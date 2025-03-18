import os
import re

# 指定文件夹路径
folder_path = r'C:\0Program\Datasets\241120\Compare\Datas\tif'

# 用来存储右边的内容（去重用集合）
right_contents = set()

# 遍历文件夹中的文件
for filename in os.listdir(folder_path):
    # 使用正则表达式提取下划线左右的内容
    match = re.match(r"(\d+)_(\d+)\.tif", filename)
    if match:
        right_content = match.group(2)  # 下划线右边的内容
        right_contents.add(right_content)  # 添加到集合中，自动去重

# 将去重后的右边内容按字母顺序排序
sorted_right_contents = sorted(right_contents)

# 输出排序后的右边内容
for right_content in sorted_right_contents:
    print(right_content)

# 输出去重后的右边内容总数
print(f"去重后的右边内容总数: {len(right_contents)}")
