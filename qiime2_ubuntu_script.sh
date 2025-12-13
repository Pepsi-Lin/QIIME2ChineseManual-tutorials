# 设置工作目录为变量，方便多次使用
wd=~/QIIME2ChineseManual/tutorials

# 进入tutorials工作目录
cd $wd

# ===== 激活QIIME 2工作环境 =====
# 您的环境名称是 qiime2（不带版本号后缀）
conda activate qiime2 2024.2.0
# 命令行前面会显示 (qiime2) 表示成功进入工作环境

# ===== 验证当前工作路径 =====
pwd
# 确认您在 ~/QIIME2ChineseManual/tutorials 目录

# ===== 列出当前目录内容 =====
ls -lh
# 查看tutorials目录下有哪些文件和文件夹

# ===== 退出QIIME 2环境（需要时使用） =====
# conda deactivate
