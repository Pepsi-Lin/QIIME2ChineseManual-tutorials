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

# 样本拆分（实际上可能不需要该步骤，因为公司返样都是拆分好的）
time qiime demux emp-single \
  --i-seqs emp-single-end-sequences.qza \
  --m-barcodes-file sample_metadata.tsv \
  --m-barcodes-column barcode-sequence \
  --o-per-sample-sequences demux.qza \
  --o-error-correction-details demux-details.qza
  # 结果统计（将上述结果可视化，这一步必须要可视化并自己查看数据）
  time qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv

# 序列质控和生成特征表
time qiime dada2 denoise-single \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left 0 \
  --p-trunc-len 120 \
  --o-representative-sequences rep-seqs-dada2.qza \
  --o-table table-dada2.qza \
  --o-denoising-stats stats-dada2.qza
此步骤是上述命令结果的可视化
qiime metadata tabulate \
  --m-input-file stats-dada2.qza \
  --o-visualization stats-dada2.qzv
我们的下游分析，将继续使用dada2的结果，需要将它们改名方便继续分析：
mv rep-seqs-dada2.qza rep-seqs.qza
mv table-dada2.qza table.qza

# 特征表和特征序列汇总
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample_metadata.tsv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

# 构建进化树用于多样性分析
time qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# 多样性计算
time qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 1103 \
  --m-metadata-file sample_metadata.tsv \
  --output-dir core-metrics-results

# Alpha多样性组间显著性分析和可视化
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

# 以faith-pd为例将互探索不同元数据条件下组间差异
# 7s，多组或多样本时计算量指数增长（beta多样性）
time qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample_metadata.tsv \
  --m-metadata-column body-site \
  --o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv \
  --p-pairwise

# 6s，多组或多样本时计算量指数增长（beta多样性）
time qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample_metadata.tsv \
  --m-metadata-column subject \
  --o-visualization core-metrics-results/unweighted-unifrac-subject-group-significance.qzv \
  --p-pairwise

# 不同部分组内和组间差异显著性分析，采用箱线图+统计表呈现
# UniFrac距离的Emperor图
qiime emperor plot \
  --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample_metadata.tsv \
  --p-custom-axes days-since-experiment-start \
  --o-visualization core-metrics-results/unweighted-unifrac-emperor-days-since-experiment-start.qzv
  
# Bray-Curtis距离的Emperor图
qiime emperor plot \
  --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
  --m-metadata-file sample_metadata.tsv \
  --p-custom-axes days-since-experiment-start \
  --o-visualization core-metrics-results/bray-curtis-emperor-days-since-experiment-start.qzv

# Alpha稀疏曲线
time qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 4000 \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization alpha-rarefaction.qzv

# 物种组成分析

# 下载物种注释数据库（Greengenes分类器）
  注意这个物种注释数据库是实时更新的，有时间再去了解下这个库是啥玩意，现在根据AI修改命令如下
echo "=== 下载Greengenes分类器 ==="
wget -O "gg-13-8-99-nb-classifier.qza" \
  "https://data.qiime2.org/2024.2/common/gg-13-8-99-nb-classifier.qza"
#运行物种注释
echo "=== 开始物种注释 ==="
time qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza \
  --p-n-jobs 1

# 生成可视化
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv




# 查看版本（确认是2024.2.0）
qiime --version






# ===== 列出当前目录内容 =====
ls -lh
# 查看tutorials目录下有哪些文件和文件夹

# ===== 退出QIIME 2环境（需要时使用） =====
# conda deactivate
