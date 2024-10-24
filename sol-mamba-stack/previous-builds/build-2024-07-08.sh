admin="tianche5"
version="1.5.8"
url='https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
script="Miniconda3-latest-Linux-x86_64-2024-07-08.sh"
bwd="/packages/apps/mamba/${version}"

wget -O "$script" "$url"

bash "$script" -sbp "$bwd"

bash create-modulefile.sh $admin $version

module load mamba/.${version}

conda install -yc conda-forge mamba=$version

# mamba update conda -yc conda-forge

packages=(
  ## base scientific libraries
  numpy
  scipy
  pandas
  natsort
  scikit-learn
  networkx
  beautifulsoup4
  # computer vision
  opencv
  # GIS pandas
  geopandas
  # symbolic math + arbitrary precision
  sympy
  mpmath
  ## plotting libraries
  matplotlib
  plotly
  bokeh
  seaborn
  ## interaction
  ipython
  # progress bars
  tqdm
  ## compression
  zstandard
  pyarrow
  feather-format
  ## serialization libraries
  pyyaml
  yaml
  ## read excel files from pandas
  openpyxl
  xlrd
  ## DASK for parallel/distributed computing
  dask
  ## install pure C++ implementation for those that want it
  micromamba
  ###
  # mamba/conda install openssl versions that will conflict 
  # with base system openssl, so install openssh + rsync
  openssh
  rsync
)

mamba install -yc conda-forge "${packages[@]}"
mamba clean --all -y

echo '\. "/packages/apps/mamba/common/activate-tracking.sh"' >> "$bwd/bin/activate"

cat << EOF

    COMMENT OUT THE ECHO IN $bwd/bin/deactivate   

    UPDATE THE BAD ACTIVATE TEXT IN 
       $bwd/lib/python<ver>/site-packages/mamba/mamba.py
    AND
       $bwd/lib/python<ver>/site-packages/mamba/utils.py

    FINALLY, CHECK $bwd/bin/activate for final line:
       \. "/packages/apps/mamba/common/activate-tracking.sh"

EOF
