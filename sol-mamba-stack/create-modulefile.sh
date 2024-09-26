who_built="${1:?ERROR -- must pass asurite of admin building}"
version="${2:?ERROR -- must pass version string}"
date=$(date "+%F")

mwd="/packages/modulefiles/apps/mamba"

! [[ -d "$mwd" ]] && mkdir -p "$mwd" || :

modulefile="${mwd}/.${version}"

cat > "$modulefile" << EOF
#%Module1.0
proc ModulesHelp { } {
  puts stderr "mamba $version"
}
module-whatis "mamba $version"

if { [module-info mode load] } {
  puts stderr {

=====================================================================
This module is intended solely for building or source activating user
python environments, i.e.,

    mamba create -n myenv -c conda-forge

or

    source activate myenv

To list available environments, run:

    mamba info --envs

See our docs: https://links.asu.edu/solpy

Any other use is NOT TESTED.
=====================================================================

  }

}

set topdir /packages/apps/mamba/${version}

prepend-path     PATH               \$topdir/bin
prepend-path     LD_LIBRARY_PATH    \$topdir/lib
prepend-path     INCLUDE            \$topdir/include
prepend-path     MANPATH            \$topdir/man
prepend-path     MANPATH            \$topdir/share/man
prepend-path     INFOPATH           \$topdir/share/info
prepend-path     CONDA_ENVS_PATH    /packages/envs

if { [module-info mode display] } {
    # RC FIELDS
    setenv RC_8X "1"
    setenv RC_PKG_MANAGER "1"
    setenv RC_OOD     "0"
    setenv RC_NOLOGIN "0"
    setenv RC_DEPRECATED "0"
    setenv RC_EXPERIMENTAL "0"
    setenv RC_DISCOURAGED "0"
    setenv RC_RETIRED "0"
    setenv RC_VIRTUAL "0"

    setenv RC_TAGS "PYTHON,PKGMAN"
    setenv RC_DESCRIPTION "mamba for building user/system python environments"
    setenv RC_URL ""
    setenv RC_NOTES ""

    setenv RC_INSTALL_DATE "$date"
    setenv RC_INSTALLER "$who_built"
    setenv RC_BUILDPATH "/packages/apps/mamba/build"

    setenv RC_MODIFY_DATE "$date"
    setenv RC_MODIFIER "$who_built"

    setenv RC_VERIFY_DATE "$date"
    setenv RC_VERIFIER "$who_built"
}

EOF
