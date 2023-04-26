------------------------------------------------------------------------
-- ASU Sol Supercomputer 2023
-- William Dizon
------------------------------------------------------------------------

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function dump(o)
   --https://stackoverflow.com/a/27028488
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function slurm_job_submit(job_desc, part_list, submit_uid)

    slurm.log_info("slurm_job_submit: received job: user:%s/%u",
      job_desc.user_name,
      submit_uid)

    --PURPOSE: assign to job user's default account if omitted
    if job_desc.account == nil then
        if job_desc.default_account == nil then
            slurm.log_info('slurm_job_submit: user %s did not specify account, and does not have a default account',
              job_desc.user_name)
            ESLURM_INVALID_ACCOUNT = 2045
            return ESLURM_INVALID_ACCOUNT
        else
            job_desc.account = job_desc.default_account
            slurm.log_info('slurm_job_submit: user %s did not specify account, attaching job to default account: %s',
              job_desc.user_name, job_desc.account)
        end
    end

    --PURPOSE: auto assign to public qos if omitted
    if job_desc.qos == nil then
        job_desc.qos = 'public'
    end

    --PURPOSE: auto assign to htc partition if omitted
    if job_desc.partition == nil then
        job_desc.partition = 'htc'
    end

    --PURPOSE: htc-labelled jobs may never exceed 4 hours
    if string.find(job_desc.partition, 'htc') and job_desc.time_limit > 240 then
        ESLURM_INVALID_TIME_LIMIT = 2051
        return ESLURM_INVALID_TIME_LIMIT
    end

    --PURPOSE: disallow 'maint' as a job name to prevent confusion
    if job_desc.name == 'MAINT' then
       ESLURM_RESERVATION_NAME_DUP = 2082
       return ESLURM_RESERVATION_NAME_DUP
    end

    --PURPOSE: exclude gpu nodes for jobs not requesting gpus
    --Pillar: JspExcludeGPUs
    JspExcludeGPUs = "g0[01-50],g[230-239]"
    
    if job_desc.tres_per_job ~= nil then
        slurm.log_info("slurm_job_submit: Requesting tres: %s", job_desc.tres_per_job)
    elseif job_desc.gres ~= nil then
        slurm.log_info("slurm_job_submit: Requesting gres: %s", job_desc.gres)
    else
	--not requesting gres? exclude gpu nodes from candidate node list
        if job_desc.partition ~= nil and string.find(job_desc.partition, 'htc') then
            --else clause below excludes gpu nodes because non were asked for
            --this route allows nodes otherwise satisfying the constraints
            --of htc (4 hours) to be used on these gpu nodes
            --by virtue of _not_ being excluded (and htc will contain all gpu nodes)
        elseif job_desc.qos == "private" then
            --also allow private use to pass through even w/o gpu (preemtible by public)
        else
            if job_desc.exc_nodes == nil then
                job_desc.exc_nodes = JspExcludeGPUs
            else
                job_desc.exc_nodes = job_desc.exc_nodes .. "," .. JspExcludeGPUs
            end
        end
    end

    --PURPOSE: exclude private nodes for jobs not "htc/public" or "general/private"
              
    private_nodes_to_exclude = ""
    slurm.log_info("slurm_job_submit: testing private node eligiblility")
    if string.find(job_desc.partition, 'general') then
        --if the user is asking for general, the only permissible cases to include
        --privately owned hardware is through the 'private' QOS
        --because this is pre-emptable
        if job_desc.qos == 'private' then
            --permissible

        elseif job_desc.qos == 'osg' then
            private_nodes_to_exclude = "cg00[1-4]"
            --permissible


        elseif job_desc.qos == 'grp_corman' then
            private_nodes_to_exclude = "g230"
            --permissible


        else
            private_nodes_to_exclude = "g230,cg00[1-4]"
            --add other private nodes here, like the 1 osg/tri-u node
        end
    elseif string.find(job_desc.partition, 'htc') then
        if job_desc.time_limit <= 240 then
            --permissible as an htc job 4 hours or less
        else
            ESLURM_INVALID_TIME_LIMIT = 2051
            return ESLURM_INVALID_TIME_LIMIT
        end
    end

    if job_desc.exc_nodes == nil then
        job_desc.exc_nodes = private_nodes_to_exclude
    else
        job_desc.exc_nodes = job_desc.exc_nodes .. "," .. private_nodes_to_exclude
    end

    --PURPOSE: exclude fpga nodes for jobs not requesting fpga
    --Pillar: JspExcludeFPGAs
    JspExcludeFPGAs = "fpga01a,fpga01i"
nodes_to_exclude = "" if job_desc.licenses == nil then--no license requested?
        if job_desc.qos == "private" then
	    --allow private use to pass without excluding nodes
	elseif string.find(job_desc.partition, 'htc') then
	    --also allow htc
	else
	    --immediately exclude fpga nodes
            if job_desc.exc_nodes == nil then
                job_desc.exc_nodes = JspExcludeFPGAs
            else
                job_desc.exc_nodes = job_desc.exc_nodes .. "," .. JspExcludeFPGAs
            end
        end
    else
        --license requested
        slurm.log_info("slurm_job_submit: Requesting license: %s", job_desc.licenses)
        if job_desc.features == nil then
            job_desc.features = job_desc.licenses
        else
	    --addition of feature reduces candidate nodes to just those with fpga
            job_desc.features = job_desc.features .. "," .. job_desc.licenses
        end
    end

    --PURPOSE: for any non-private job, add that qos as a feature-requirement (constraint)
    if job_desc.qos ~= "private" then
        --the reason why jobs with qos private are left untouched is
        --that adding features reduces potential candidate nodes.
        --using private is intended to take advantage of every possible
        --available unused cycle and wants the widest possible choices
        if job_desc.features == nil then
            job_desc.features = job_desc.qos
        else
            job_desc.features = job_desc.features .. "," .. job_desc.qos
        end
        slurm.log_info("slurm_job_submit: qos specified != 'private'; appending qos as feature (current constraints: %s)", job_desc.features)
    end

    --PURPOSE: detect generic %u (invalid entry) for mail user and substitute with asurite
    if job_desc.mail_user == "%u@asu.edu" then
        --template value should be changed in all circumstances, mailtype kept intact
        job_desc.mail_user = job_desc.user_name .. "@asu.edu"
    elseif job_desc.mail_user == nil then
        --nil value will be changed in all circumstances, mailtype set to NONE
        job_desc.mail_user = job_desc.user_name .. "@asu.edu"
    end

    slurm.log_info("slurm_job_submit: excluding nodes: %s", dump(job_desc.exc_nodes))
    slurm.log_info("slurm_job_submit: final features: %s", dump(job_desc.features))
    slurm.log_info("slurm_job_submit: job from user:%s/%u acct:%s minutes:%u cores:%u    -%u nodes:%u-%u shared:%u partition:%s QOS:%s GRES:%s",
      job_desc.user_name,
      submit_uid,
      job_desc.account,
      job_desc.time_limit,
      job_desc.min_cpus,
      job_desc.max_cpus,
      job_desc.min_nodes,
      job_desc.max_nodes,
      job_desc.shared,
      tostring(job_desc.partition),
      tostring(job_desc.qos),
      tostring(job_desc.tres_per_job))

    return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
    --return slurm.FAILURE
end

