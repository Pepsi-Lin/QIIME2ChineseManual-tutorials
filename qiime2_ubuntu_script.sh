# 设置工作目录为变量，方便多次使用
wd=/mnt/e/qiime2/tutorials

# 进入tutorials工作目录
cd $wd

# 激活环境（就这样写，不加版本号）
conda activate qiime2

# 创建子目录（mkdir）emp = Earth Microbiome Project（地球微生物组计划），single-end = 单端测序，sequences = 序列数据，-p 参数的作用（可以创建多层目录，如 mkdir -p a/b/c）
mkdir -p emp-single-end-sequences
# 3.6M
wget \
  -O "emp-single-end-sequences/barcodes.fastq.gz" \
  "https://data.qiime2.org/2021.2/tutorials/moving-pictures/emp-single-end-sequences/barcodes.fastq.gz"
# 24M
wget \
  -O "emp-single-end-sequences/sequences.fastq.gz" \
  "https://data.qiime2.org/2021.2/tutorials/moving-pictures/emp-single-end-sequences/sequences.fastq.gz"

# 生成qiime2要求的对象格式（time统计用于计算时间，这个命令方面做大项目时来掌握时间）
time qiime tools import \
  --type EMPSingleEndSequences \
  --input-path emp-single-end-sequences \
  --output-path emp-single-end-sequences.qza

接下来是样本拆分，没看了
  

# 查看版本（确认是2024.2.0）
qiime --version






# ===== 列出当前目录内容 =====
ls -lh
# 查看tutorials目录下有哪些文件和文件夹

# ===== 退出QIIME 2环境（需要时使用） =====
# conda deactivate
