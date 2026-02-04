#!/bin/bash
# ===============================================================================
# QIIME 2 微生物组数据完整分析流程
# ===============================================================================
# 教程数据：Moving Pictures Tutorial（人体微生物组时间序列研究）
# QIIME 2 版本：2024.2
# 物种数据库：Greengenes 13.8 (2024.2版本)
# 作者：Dr. Lin
# 单位：湖南农业大学 环境与生态学院
# 更新日期：2026-01-07
# ===============================================================================
# 
# 分析目标：
# 本流程分析两个人体部位（肠道、皮肤）在不同时间点的微生物群落变化
# 
# 主要步骤：
# 1. 数据准备 → 2. 质控去噪 → 3. 多样性分析 → 4. 物种组成分析
#
# 运行环境：
# - 操作系统：Ubuntu 24.04 LTS (WSL2)
# - 内存要求：8GB以上（物种注释步骤需要）
# - 磁盘空间：至少5GB
# ===============================================================================

# ===============================================================================
# 第一部分：环境配置与工作目录设置
# ===============================================================================

# 设置工作目录为变量，方便多次使用
# 说明：使用变量后，后续可以用 $wd 快速引用此路径
wd=/mnt/e/qiime2/tutorials

# 进入tutorials工作目录
# 说明：所有文件都将保存在此目录下，便于集中管理
cd $wd

# 激活QIIME 2环境
# 说明：QIIME 2安装在conda虚拟环境中，激活后才能使用qiime命令
# 注意：环境名称是 qiime2，不需要加版本号
conda activate qiime2

# ===============================================================================
# 第二部分：测序数据下载
# ===============================================================================
# 
# 本部分下载教程数据集，包含：
# - barcodes.fastq.gz：样本标签序列（用于区分不同样本）
# - sequences.fastq.gz：实际的16S rRNA基因测序数据
# 
# 数据说明：
# - 来源：两名志愿者（Subject 1和Subject 2）
# - 采样部位：肠道（gut）、左手掌（left palm）、右手掌（right palm）、舌头（tongue）
# - 时间点：实验开始后的不同天数（0-84天）
# - 测序平台：Illumina单端测序
# ===============================================================================

# 创建子目录存放原始测序数据
# 命名说明：
# - emp = Earth Microbiome Project（地球微生物组计划，一个标准化的微生物组研究项目）
# - single-end = 单端测序（与双端测序paired-end相对）
# - sequences = 序列数据
# -p 参数：如果父目录不存在会自动创建，类似于 mkdir -p a/b/c 会创建a、b、c三级目录
mkdir -p emp-single-end-sequences

# 下载barcode文件（样本标签，3.6MB）
# 说明：每个样本都有唯一的barcode序列，用于在混合测序后识别样本来源
# wget参数：
#   -O：指定输出文件名和路径
wget \
  -O "emp-single-end-sequences/barcodes.fastq.gz" \
  "https://data.qiime2.org/2021.2/tutorials/moving-pictures/emp-single-end-sequences/barcodes.fastq.gz"

# 下载序列文件（实际的DNA序列数据，24MB）
# 说明：包含所有样本的16S rRNA基因V4区测序结果
wget \
  -O "emp-single-end-sequences/sequences.fastq.gz" \
  "https://data.qiime2.org/2021.2/tutorials/moving-pictures/emp-single-end-sequences/sequences.fastq.gz"

# ===============================================================================
# 第三部分：数据导入QIIME 2格式
# ===============================================================================
#
# QIIME 2使用专有的.qza格式（QIIME 2 Artifact）存储数据
# 优点：
# - 包含数据来源和处理历史（溯源性）
# - 防止数据类型错误
# - 便于数据共享和重现分析
# ===============================================================================

# 将原始测序数据转换为QIIME 2格式
# 说明：
# - time命令用于统计执行时间，便于评估大数据集的处理时长
# - EMPSingleEndSequences是QIIME 2定义的数据类型，表示EMP格式的单端测序数据
# - 生成的.qza文件包含原始数据+元数据（类型、来源等）
# 预计耗时：约10秒
time qiime tools import \
  --type EMPSingleEndSequences \
  --input-path emp-single-end-sequences \
  --output-path emp-single-end-sequences.qza

# ===============================================================================
# 第四部分：样本拆分（Demultiplexing）
# ===============================================================================
#
# 什么是样本拆分？
# - 多个样本混合在一起测序（节约成本）
# - 通过barcode序列识别每条序列属于哪个样本
# - 拆分后每个样本的序列独立存储
#
# 实际工作中的注意：
# - 测序公司通常会返回已拆分的数据（每个样本一个文件）
# - 如果已拆分，可以跳过此步骤
# - 教程数据是混合的，需要执行拆分
# ===============================================================================

# 根据barcode序列进行样本拆分
# 参数说明：
# - --m-barcodes-file：元数据文件，包含样本ID和对应的barcode序列
# - --m-barcodes-column barcode-sequence：指定元数据文件中barcode列的列名
# 输出文件：
# - demux.qza：拆分后的序列（按样本分组）
# - demux-details.qza：拆分统计（成功率、barcode纠错情况）
# 预计耗时：约30秒
time qiime demux emp-single \
  --i-seqs emp-single-end-sequences.qza \
  --m-barcodes-file sample_metadata.tsv \
  --m-barcodes-column barcode-sequence \
  --o-per-sample-sequences demux.qza \
  --o-error-correction-details demux-details.qza

# 生成拆分结果的质量报告
# 重要性：★★★★★（必须查看！）
# 用途：
# 1. 查看每个样本的序列数量（是否均衡）
# 2. 查看序列质量分布（Interactive Quality Plot）
# 3. 确定后续质控参数（--p-trim-left 和 --p-trunc-len）
# 
# 如何查看：
# - 方法1：qiime tools view demux.qzv
# - 方法2：上传到 https://view.qiime2.org
# - 方法3：在Windows文件管理器中双击文件
# 预计耗时：约5秒
time qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv

# ===============================================================================
# 第五部分：序列质控和特征表生成（DADA2）
# ===============================================================================
#
# DADA2算法的主要功能：
# 1. 质量过滤：去除低质量序列
# 2. 去噪（Denoising）：纠正测序错误
# 3. 去除嵌合体（Chimera）：去除PCR产生的假序列
# 4. 生成ASV（扩增子序列变体）：相当于100%相似度的OTU
#
# ASV vs OTU：
# - ASV：精确到单个碱基的差异，分辨率更高
# - OTU：传统方法，通常97%相似度聚类
# - DADA2生成ASV，比OTU更准确
#
# 参数选择的重要性：
# - --p-trim-left：去除5'端低质量碱基（如前13bp）
# - --p-trunc-len：在指定位置截断序列（根据质量图确定）
# - 这两个参数直接影响数据保留量和质量！
# ===============================================================================

# DADA2去噪和特征表生成（核心步骤）
# 参数说明：
# - --p-trim-left 0：从5'端（序列开头）去除0个碱基
#   （如果demux.qzv显示前面几个碱基质量差，可以设为13等）
# - --p-trunc-len 120：在第120个碱基处截断
#   （需根据demux.qzv的质量曲线确定，通常选择质量开始下降的位置）
# 
# 输出文件说明：
# - rep-seqs-dada2.qza：代表性序列（每个ASV的DNA序列）
# - table-dada2.qza：特征表（ASV在各样本中的丰度，类似于OTU表）
# - stats-dada2.qza：统计信息（每步保留的序列数）
#
# 预计耗时：约1分钟（教程数据），真实数据可能需要数小时
time qiime dada2 denoise-single \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left 0 \
  --p-trunc-len 120 \
  --o-representative-sequences rep-seqs-dada2.qza \
  --o-table table-dada2.qza \
  --o-denoising-stats stats-dada2.qza

# 可视化DADA2统计结果
# 用途：查看每个样本在各步骤的序列保留情况
# - input：输入序列数
# - filtered：质量过滤后保留数
# - denoised：去噪后保留数  
# - merged：合并后保留数（双端测序才有）
# - non-chimeric：去除嵌合体后的最终序列数
# 
# 如何判断结果好坏：
# - 如果filtered阶段损失>50%，说明参数可能不合适
# - 如果non-chimeric阶段损失>50%，可能样本污染或PCR问题
qiime metadata tabulate \
  --m-input-file stats-dada2.qza \
  --o-visualization stats-dada2.qzv

# 重命名文件以简化后续分析
# 说明：去掉"-dada2"后缀，使命令更简洁
# 原因：下游分析中这些文件会被频繁使用
mv rep-seqs-dada2.qza rep-seqs.qza
mv table-dada2.qza table.qza

# ===============================================================================
# 第六部分：特征表和序列汇总
# ===============================================================================
#
# 本部分生成两个重要的摘要文件：
# 1. 特征表摘要：了解数据集的整体特征
# 2. 序列摘要：查看具体的ASV序列
# ===============================================================================

# 生成特征表摘要
# 重要性：★★★★★（必须查看！）
# 包含信息：
# - 样本数量
# - 特征（ASV）数量
# - 每个样本的序列总数（测序深度）
# - 特征频率分布
#
# 重要用途：确定多样性分析的抽平深度（--p-sampling-depth）
# - 查看"Frequency per sample"表格
# - 选择一个合适的深度（通常是最小值附近，但不要太小）
# - 例如：最小值1000，可以选择1000或稍低的值
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample_metadata.tsv

# 生成代表性序列摘要
# 用途：
# - 查看每个ASV的DNA序列
# - 可以BLAST比对查看可能的物种（后续物种注释前的参考）
# - 查看序列长度分布
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

# ===============================================================================
# 第七部分：系统发育树构建
# ===============================================================================
#
# 为什么需要系统发育树？
# - UniFrac距离计算需要进化树
# - UniFrac考虑物种间的进化关系，比Bray-Curtis更准确
# - Faith's PD（系统发育多样性）指标也需要进化树
#
# 构建流程（4个步骤，自动完成）：
# 1. MAFFT多序列比对：将所有ASV序列比对到一起
# 2. 掩码（Mask）：去除高变异或gap过多的位点
# 3. FastTree建树：基于比对结果构建系统发育树
# 4. 添加根（Midpoint rooting）：将无根树转为有根树
# ===============================================================================

# 一步完成：序列比对 + 掩码 + 建树 + 添加根
# 输出文件说明：
# - aligned-rep-seqs.qza：多序列比对结果
# - masked-aligned-rep-seqs.qza：掩码后的比对（去除了不可靠的位点）
# - unrooted-tree.qza：无根树
# - rooted-tree.qza：有根树（用于多样性分析）
#
# 预计耗时：约30秒（教程数据），真实数据可能需要数分钟
time qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# ===============================================================================
# 第八部分：核心多样性指标计算
# ===============================================================================
#
# 核心多样性分析是微生物组分析的核心！
# 
# Alpha多样性（样本内多样性）：
# - Shannon指数：考虑丰富度和均匀度
# - Simpson指数：更关注优势物种
# - Faith's PD：系统发育多样性，考虑进化距离
# - Observed features：观察到的ASV数量
# - Evenness（Pielou's）：物种分布均匀程度
#
# Beta多样性（样本间差异）：
# - Bray-Curtis：基于丰度的差异
# - Jaccard：基于有无的差异（不考虑丰度）
# - Unweighted UniFrac：考虑进化关系，不考虑丰度
# - Weighted UniFrac：同时考虑进化关系和丰度
#
# 抽平（Rarefaction）的必要性：
# - 不同样本的测序深度不同
# - 深度高的样本会检测到更多物种（测序偏差）
# - 抽平使所有样本深度一致，便于比较
# - 缺点：会丢失一些数据
# ===============================================================================

# 计算所有核心多样性指标
# 关键参数：
# - --p-sampling-depth 1103：抽平深度
#   重要！此值需根据table.qzv确定！
#   - 查看table.qzv中"Frequency per sample"
#   - 选择一个平衡点：不要太高（丢样本）也不要太低（丢信息）
#   - 1103是教程数据的合适值，您的数据需要自行确定！
#
# 输出目录：core-metrics-results/
# 包含10+个文件：
# - *_vector.qza：alpha多样性结果
# - *_distance_matrix.qza：beta多样性距离矩阵  
# - *_pcoa_results.qza：PCoA降维结果
# - *.qzv：可视化文件
#
# 预计耗时：1-2分钟
time qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 1103 \
  --m-metadata-file sample_metadata.tsv \
  --output-dir core-metrics-results

# ===============================================================================
# 第九部分：Alpha多样性统计检验
# ===============================================================================
#
# 统计目的：
# - 比较不同分组间的alpha多样性是否有显著差异
# - 例如：肠道vs皮肤，不同时间点等
#
# 统计方法（自动选择）：
# - 两组：Mann-Whitney U检验（非参数）
# - 多组：Kruskal-Wallis H检验（非参数）
# 
# 输出内容：
# - 分组箱线图
# - 统计检验p值
# - 样本大小
# ===============================================================================

# Faith's系统发育多样性组间比较
# 意义：反映群落的进化多样性
# 用途：比较不同分组（如body-site, subject）的PD差异
# 结果解读：p < 0.05 表示组间有显著差异
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

# 均匀度（Evenness）组间比较  
# 意义：反映物种丰度分布的均匀程度
# 高均匀度：物种丰度相近，无明显优势种
# 低均匀度：少数物种占主导地位
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

# ===============================================================================
# 第十部分：Beta多样性统计检验
# ===============================================================================
#
# Beta多样性分析的目的：
# - 比较不同分组之间的群落组成差异
# - 检验组间差异是否显著
#
# 统计方法：PERMANOVA（置换多元方差分析）
# - 原理：通过置换检验评估分组因素对群落差异的解释度
# - 输出：R²（解释度）和p值（显著性）
# - R² = 组间差异占总差异的比例
#
# --p-pairwise参数：
# - 进行两两比较（类似于事后检验）
# - 当有3+个组时很有用
# - 例如：gut vs left palm, gut vs right palm等
# ===============================================================================

# 不同身体部位间的UniFrac距离显著性检验
# 问题：肠道、皮肤、舌头的微生物群落组成是否显著不同？
# --m-metadata-column body-site：按采样部位分组
# 预计耗时：约7秒
# 注意：样本数多或分组多时，计算量呈指数增长
time qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample_metadata.tsv \
  --m-metadata-column body-site \
  --o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv \
  --p-pairwise

# 不同个体间的UniFrac距离显著性检验
# 问题：两个志愿者的微生物群落是否显著不同？
# --m-metadata-column subject：按个体分组
# 预计耗时：约6秒
time qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample_metadata.tsv \
  --m-metadata-column subject \
  --o-visualization core-metrics-results/unweighted-unifrac-subject-group-significance.qzv \
  --p-pairwise

# ===============================================================================
# 第十一部分：PCoA降维可视化（Emperor图）
# ===============================================================================
#
# PCoA（主坐标分析）是什么？
# - 将高维的距离矩阵降维到2D或3D空间
# - 类似于PCA，但可用于任何距离矩阵
# - 使复杂的样本关系变得直观可视化
#
# Emperor图的特点（交互式）：
# - 可旋转3D图形
# - 可按元数据着色（如body-site, subject）
# - 可添加动画（如时间序列）
# - 可显示轴的解释度（如PC1 explains 30%）
#
# 自定义坐标轴的意义：
# - --p-custom-axes days-since-experiment-start
# - 将时间作为一个坐标轴
# - 可以直观看到群落随时间的变化轨迹
# ===============================================================================

# UniFrac距离的PCoA可视化
# 用途：观察样本在进化距离空间中的分布
# 自定义轴：以实验天数作为坐标轴之一
# 可视化效果：
# - 相似样本聚在一起
# - 不同组样本分开
# - 可以看到时间变化趋势
qiime emperor plot \
  --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample_metadata.tsv \
  --p-custom-axes days-since-experiment-start \
  --o-visualization core-metrics-results/unweighted-unifrac-emperor-days-since-experiment-start.qzv
  
# Bray-Curtis距离的PCoA可视化
# 用途：观察样本在物种组成空间中的分布
# 与UniFrac的区别：
# - Bray-Curtis只考虑物种丰度
# - UniFrac还考虑物种间的进化关系
# - 两者结果可能不同，互为补充
qiime emperor plot \
  --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
  --m-metadata-file sample_metadata.tsv \
  --p-custom-axes days-since-experiment-start \
  --o-visualization core-metrics-results/bray-curtis-emperor-days-since-experiment-start.qzv

# ===============================================================================
# 第十二部分：Alpha稀疏曲线分析
# ===============================================================================
#
# 稀疏曲线（Rarefaction Curve）的作用：
# 1. 评估测序深度是否充分
#    - 曲线趋于平坦：测序已饱和，物种基本被检测到
#    - 曲线持续上升：测序不足，还有未检测到的物种
#
# 2. 比较不同样本/组的物种丰富度
#    - 在相同测序深度下比较alpha多样性
#    - 可按元数据分组查看（如body-site, subject）
#
# 3. 确定合适的抽平深度
#    - 观察哪个深度时各组差异最明显
#    - 验证之前选择的抽平深度是否合适
#
# --p-max-depth参数：
# - 设置为略高于最大样本深度
# - 本例4000是根据table.qzv中的最大深度确定的
# - 太小：看不到完整曲线；太大：浪费计算资源
# ===============================================================================

# 生成alpha多样性稀疏曲线
# 输出：交互式图表
# - X轴：测序深度（Sequences per sample）
# - Y轴：Alpha多样性指标（Shannon, Observed features等）
# - 分组：可按元数据着色
#
# 预计耗时：1-2分钟
time qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 4000 \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization alpha-rarefaction.qzv

# ===============================================================================
# 第十三部分：物种分类注释
# ===============================================================================
#
# 物种注释的重要性：
# - ASV本身只是DNA序列，不知道是什么物种
# - 通过与参考数据库比对，推断物种分类信息
# - 得到从界、门、纲、目、科、属、种的完整分类
#
# 分类器的选择：
# 1. Greengenes（本脚本使用）
#    - 数据库版本：13.8（较旧，但稳定）
#    - 文件大小：约30MB
#    - 内存需求：2-3GB
#    - 优点：速度快，资源需求低
#    - 适用：教程学习、资源受限环境
#
# 2. Silva（另一选择）
#    - 数据库版本：138（较新）
#    - 文件大小：约142MB
#    - 内存需求：6-8GB
#    - 优点：数据更新、物种更全
#    - 适用：真实项目、资源充足环境
#
# 分类方法：
# - 朴素贝叶斯分类器（Naive Bayes Classifier）
# - 基于k-mer特征进行机器学习分类
# - 给出分类结果和置信度（Confidence）
# ===============================================================================

# 下载Greengenes物种分类器
# 注意：分类器是预训练的机器学习模型
# 版本说明：
# - 使用2024.2版本（与QIIME 2版本匹配）
# - 如果版本不匹配会报错（scikit-learn版本冲突）
# 
# 训练区域：
# - 515F-806R引物扩增的V4区
# - 如果您的数据使用其他引物，需要下载对应的分类器
# - 或者自己训练分类器（参考QIIME 2文档）
echo "=== 下载Greengenes分类器 ==="
wget -O "gg-13-8-99-nb-classifier.qza" \
  "https://data.qiime2.org/2024.2/common/gg-13-8-99-nb-classifier.qza"

# 运行物种分类注释
# 参数说明：
# - --p-n-jobs 1：使用单线程
#   作用：降低内存需求，避免系统崩溃
#   注意：多线程会提速，但需要更多内存
#         如果内存充足（16GB+），可以设为4或更高
#
# 输出：taxonomy.qza
# 包含：每个ASV的完整分类信息
# 格式：k__Bacteria; p__Bacteroidetes; c__Bacteroidia; ...
#
# 预计耗时：2-5分钟（教程数据），真实数据可能需要10-30分钟
echo "=== 开始物种注释 ==="
time qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza \
  --p-n-jobs 1

# 生成物种注释表的可视化
# 用途：
# - 以表格形式查看每个ASV的分类信息
# - 包含分类路径和置信度
# - 可以搜索、排序、筛选
qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

# 生成物种组成堆叠柱状图
# 重要性：★★★★★（最直观的结果展示！）
# 
# 图表特点（交互式）：
# - X轴：样本（可按元数据排序或分组）
# - Y轴：相对丰度（百分比）
# - 颜色：不同物种/分类单元
# - 可切换分类学层级：界→门→纲→目→科→属→种
# - 可按元数据分组：body-site, subject, time等
#
# 实际应用：
# - 观察不同样本的物种组成差异
# - 识别优势物种
# - 发现时间动态变化
# - 比较不同处理组的物种差异
qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample_metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

# ===============================================================================
# 分析流程全部完成！
# ===============================================================================
#
# 生成的主要结果文件：
# 
# 1. 质量报告：
#    - demux.qzv（序列质量）
#    - stats-dada2.qzv（去噪统计）
#
# 2. 数据摘要：
#    - table.qzv（特征表）
#    - rep-seqs.qzv（代表序列）
#
# 3. 多样性分析：
#    - core-metrics-results/（所有多样性结果）
#    - alpha-rarefaction.qzv（稀疏曲线）
#
# 4. 物种组成：
#    - taxonomy.qzv（物种注释表）
#    - taxa-bar-plots.qzv（物种柱状图）★★★
#
# 查看结果的三种方式：
# 1. 命令行：qiime tools view 文件名.qzv
# 2. 在线查看：https://view.qiime2.org（拖入.qzv文件）
# 3. Windows：双击.qzv文件（自动用浏览器打开）
#
# 下一步建议：
# 1. 先查看taxa-bar-plots.qzv了解物种组成
# 2. 查看PCoA图（Emperor）了解样本聚类
# 3. 查看统计检验结果确定显著差异
# 4. 根据需求进行进一步分析（差异分析、功能预测等）
# ===============================================================================
