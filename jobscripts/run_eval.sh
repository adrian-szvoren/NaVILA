#$ -l tmem=36G
#$ -l h_rt=500:00:00
#$ -l gpu=true,gpu_type=!(gtx1080ti|titanx|rtx2080ti|rtx3090|rtx4070ti|v100)

#$ -S /bin/bash
#$ -j y
#$ -N navila_setup
#$ -wd /SAN/intelsys/robot-vla-attack

start=`date +%s`

scl enable devtoolset-9 bash
nvidia-smi

source /share/apps/source_files/python/python-3.10.0.source

# python3 -m venv navila-venv
source navila-venv/bin/activate
pip install --upgrade pip
cd NaVILA/evaluation

bash scripts/eval/r2r.sh ../checkpoints/navila-llama3-8b-8f 1 0 "0"

end=`date +%s`
runtime=$((end-start))
hours=$((runtime / 3600))
minutes=$(( (runtime % 3600) / 60 ))
seconds=$(( (runtime % 3600) % 60 ))
echo "Runtime: $hours:$minutes:$seconds (hh:mm:ss)"