import os


def get_date_from_folder(folder_name):
    # 按照下划线分割文件夹名
    parts = folder_name.split('_')
    if len(parts) >= 8:  # 确保文件夹名至少有足够的部分
        date_str = parts[-4]  # 时间信息
        if len(date_str) == 8:  # 确保数字位数
            year = date_str[:4]
            month = date_str[4:6]
            day = date_str[6:8]
            # print(f"从文件夹 {folder_name} 提取的日期: {year}-{month}-{day}")  # 调试信息
            return f"{year}-{month}-{day}"
    # print(f"文件夹 {folder_name} 没有找到有效的日期.")  # 调试信息
    return None


def match_tif_with_folder(tif_dir, folder_dir):
    # 遍历.tif文件所在的文件夹
    for tif_filename in os.listdir(tif_dir):
        if tif_filename.endswith('.tif'):
            # 获取.tif文件的完整文件名（去掉扩展名）
            tif_name = os.path.splitext(tif_filename)[0]
            # print(f"正在处理文件: {tif_filename}（文件名: {tif_name}）")  # 调试信息

            # 遍历目标文件夹中的所有子文件夹
            for folder_name in os.listdir(folder_dir):
                folder_path = os.path.join(folder_dir, folder_name)
                if os.path.isdir(folder_path):  # 确保是文件夹
                    # 遍历子文件夹中的所有子文件夹
                    for subfolder_name in os.listdir(folder_path):
                        subfolder_path = os.path.join(folder_path, subfolder_name)
                        if os.path.isdir(subfolder_path):  # 确保是子文件夹
                            # 如果.tif文件名的后六位与子文件夹名的后六位匹配
                            if tif_name[-6:] == subfolder_name[-6:]:
                                # 提取文件夹中的日期（时间信息）
                                date = get_date_from_folder(subfolder_name)
                                if date:
                                    # print(f"文件 {tif_filename} 匹配到子文件夹 {subfolder_name}，时间为 {date}")
                                    print(f"{tif_filename.split('.')[0]}：{date}")
                                    break  # 匹配成功后跳出子文件夹遍历，开始处理下一个.tif文件
                    else:
                        continue  # 若没有找到匹配的子文件夹，继续检查下一个子文件夹
                    break  # 匹配成功后跳出子文件夹遍历，开始处理下一个.tif文件


# 设置.tif文件所在的目录和包含文件夹的目录
tif_directory = r'C:\0Program\Datasets\241120\Compare\Datas\B'  # .tif文件所在的路径
folder_directory = r'C:\0Program\Datasets\241120\inputs'  # 包含文件夹的路径

# 调用函数进行匹配
match_tif_with_folder(tif_directory, folder_directory)
