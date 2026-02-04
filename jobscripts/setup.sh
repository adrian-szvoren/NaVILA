#$ -l tmem=36G
#$ -l h_rt=500:00:00
#$ -l gpu=true,gpu_type=!(gtx1080ti|titanx|rtx2080ti|rtx3090|rtx4070ti|v100)

#$ -S /bin/bash
#$ -j y
#$ -N benchmark-openvla-full
#$ -wd /SAN/intelsys/robot-vla-attack

start=`date +%s`

scl enable devtoolset-9 bash
nvidia-smi

source /share/apps/source_files/python/python-3.10.0.source

python3 -m venv navila-venv
source navila-venv/bin/activate
pip install --upgrade pip

# Build Habitat-Sim & Lab (v0.1.7) from Source
git clone --branch v0.1.7 https://github.com/facebookresearch/habitat-sim.git
cd habitat-sim
pip install -r requirements.txt
python3 setup.py install --headless
cd ..

git clone --branch v0.1.7 git@github.com:facebookresearch/habitat-lab.git
cd habitat-lab
python3 -m pip install -r requirements.txt
python3 -m pip install -r habitat_baselines/rl/requirements.txt
python3 -m pip install -r habitat_baselines/rl/ddppo/requirements.txt
python3 setup.py develop --all
cd ..

# Install VLN-CE Dependencies
python3 evaluation/scripts/habitat_sim_autofix.py # replace habitat_sim/utils/common.py
pip install -r evaluation/requirements.txt

# Install FlashAttention2
pip install https://github.com/Dao-AILab/flash-attention/releases/download/v2.5.8/flash_attn-2.5.8+cu122torch2.3cxx11abiFALSE-cp310-cp310-linux_x86_64.whl

# Install VILA (assum in root dir)
pip install -e .
pip install -e ".[train]"
pip install -e ".[eval]"

# Install HF's Transformers
pip install git+https://github.com/huggingface/transformers@v4.37.2
site_pkg_path=$(python -c 'import site; print(site.getsitepackages()[0])')
cp -rv ./llava/train/transformers_replace/* $site_pkg_path/transformers/
cp -rv ./llava/train/deepspeed_replace/* $site_pkg_path/deepspeed/

pip install webdataset==0.1.103

# Download dataset
wget https://kaldir.vc.cit.tum.de/matterport/download_mp.py
# requires running with python 2.7
python download_mp.py --task habitat -o data/scene_datasets/mp3d/

wget https://drive.google.com/uc?id=1fo8F4NKgZDH-bPSdVU3cONAkt5EW-tyr
mkdir data/datasets
unzip R2R_VLNCE_v1-3_preprocessed.zip -d data/datasets/

wget https://drive.google.com/file/d/145xzLjxBaNTbVgBfQ8e9EsBAV8W-SM0t/view
unzip RxR_VLNCE_v0 -d data/datasets/

end=`date +%s`
runtime=$((end-start))
hours=$((runtime / 3600))
minutes=$(( (runtime % 3600) / 60 ))
seconds=$(( (runtime % 3600) % 60 ))
echo "Runtime: $hours:$minutes:$seconds (hh:mm:ss)"