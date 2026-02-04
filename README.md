# QIIME 2 微生物组数据分析教程

完整的16S rRNA基因扩增子测序数据分析流程

## 📖 项目简介

本项目提供了一套完整的QIIME 2微生物组数据分析流程，适用于16S rRNA基因测序数据。基于QIIME 2官方Moving Pictures教程，针对初学者进行了详细注释。

**分析数据**：两名志愿者在84天内，4个身体部位（肠道、左手掌、右手掌、舌头）的微生物群落时间序列数据

## 🎯 分析内容

- ✅ 序列质控与去噪（DADA2）
- ✅ Alpha多样性分析（物种丰富度、均匀度等）
- ✅ Beta多样性分析（样本间差异、PCoA降维）
- ✅ 系统发育分析（进化树构建、UniFrac距离）
- ✅ 物种分类注释（Greengenes数据库）
- ✅ 可视化（交互式图表）

## 🔧 环境要求

- **操作系统**: Ubuntu 24.04 LTS (推荐WSL2)
- **QIIME 2版本**: 2024.2
- **内存**: ≥8GB（物种注释步骤必需）
- **磁盘空间**: ≥5GB
- **网络**: 需要下载测序数据和分类器

## 📦 QIIME 2 安装
```bash
# 下载安装配置文件
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.2-py38-linux-conda.yml

# 创建conda环境
conda env create -n qiime2 --file qiime2-amplicon-2024.2-py38-linux-conda.yml

# 激活环境
conda activate qiime2

# 验证安装
qiime --version
```

## 🚀 快速开始
```bash
# 1. 克隆仓库
git clone https://github.com/你的用户名/qiime2-tutorial.git
cd qiime2-tutorial

# 2. 修改工作目录（根据实际情况）
# 编辑脚本第一行：wd=/your/work/directory

# 3. 运行完整流程
bash qiime2_analysis_pipeline.sh
```

## 📂 输出文件结构
```
qiime2/tutorials/
├── emp-single-end-sequences/        # 原始数据
├── *.qza                            # QIIME 2数据文件
├── *.qzv                            # 可视化文件
├── core-metrics-results/            # 多样性分析结果
│   ├── faith-pd-group-significance.qzv
│   ├── unweighted-unifrac-emperor-*.qzv
│   └── ...
├── taxa-bar-plots.qzv               # 物种组成柱状图★
├── taxonomy.qzv                     # 物种注释表
└── alpha-rarefaction.qzv            # 稀疏曲线
```

## 🔍 结果查看

### 方法1：命令行查看
```bash
qiime tools view taxa-bar-plots.qzv
```

### 方法2：在线查看
1. 访问 https://view.qiime2.org
2. 拖入 `.qzv` 文件

### 方法3：Windows直接打开
- 在文件管理器中双击 `.qzv` 文件

## 📊 关键结果文件

| 文件名 | 内容 | 重要性 |
|--------|------|--------|
| `taxa-bar-plots.qzv` | 物种组成堆叠图（交互式） | ★★★★★ |
| `table.qzv` | 特征表摘要 | ★★★★★ |
| `demux.qzv` | 序列质量报告 | ★★★★★ |
| `core-metrics-results/unweighted-unifrac-emperor-*.qzv` | PCoA可视化 | ★★★★ |
| `alpha-rarefaction.qzv` | 稀疏曲线 | ★★★★ |

## ⚠️ 常见问题

### Q1: WSL闪退？
**A**: 增加WSL内存配置
1. 创建文件：`C:\Users\你的用户名\.wslconfig`
2. 添加内容：
```ini
[wsl2]
memory=8GB
processors=4
```
3. 重启：`wsl --shutdown`（PowerShell中执行）

### Q2: 物种注释很慢？
**A**: 正常现象
- 教程数据：2-5分钟
- 真实数据：10-30分钟
- 使用 `--p-n-jobs 4` 可加速（需要更多内存）

### Q3: 如何确定抽平深度？
**A**: 查看 `table.qzv`
1. 打开 "Interactive Sample Detail"
2. 查看最小测序深度
3. 选择一个平衡值（不要太高也不要太低）

### Q4: Greengenes vs Silva？
**A**: 
- **Greengenes**: 快速、低内存、适合学习
- **Silva**: 更新、更全、适合发表

## 📚 参考资料

- [QIIME 2官方文档](https://docs.qiime2.org/2024.2/)
- [Moving Pictures教程](https://docs.qiime2.org/2024.2/tutorials/moving-pictures/)
- [QIIME 2论坛](https://forum.qiime2.org/)

## 👨‍🏫 作者信息

- **作者**: Dr. Lin
- **单位**: 湖南农业大学 环境与生态学院
- **邮箱**: [你的邮箱]

## 📄 许可证

MIT License - 自由使用和修改

## 🙏 致谢

感谢QIIME 2开发团队提供的优秀工具和详细文档
