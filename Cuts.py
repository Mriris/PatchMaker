import os
import numpy as np
import rasterio
from rasterio.mask import mask
from shapely.geometry import shape, mapping
from shapely.ops import unary_union
import geopandas as gpd
import re

# 设置输入和输出目录
input_dir_a_b = r"D:\0Program\Datasets\241120\Compare\TEMP\A"  # 存放 A_B.tif 的文件夹
input_dir_geo = r"D:\0Program\Datasets\241120\Compare\TEMP"  # 存放地名子文件夹的文件夹
output_dir = r"D:\0Program\Datasets\241120\Compare\TEMP\Final"  # 输出文件夹

# 确保输出目录存在
os.makedirs(output_dir, exist_ok=True)

# 遍历所有 A_B.tif 文件
for file_name in os.listdir(input_dir_a_b):
    if not file_name.endswith(".tif") or "_" not in file_name:
        continue

    # 提取 A_B 中的 B（作为子文件夹名字）
    match = re.match(r"(.*)_(.*).tif", file_name)
    if not match:
        continue
    print("文件名：", file_name)
    b_part = match.group(2)

    # 构造子文件夹路径
    sub_folder_path = os.path.join(input_dir_geo, b_part)
    if not os.path.isdir(sub_folder_path):
        print(f"未找到子文件夹：{sub_folder_path}")
        continue

    # 在子文件夹中查找以 _slc_multilooked_pwr_fil_geo_db_meta.tif 结尾的文件
    matching_file = None
    for f in os.listdir(sub_folder_path):
        if f.endswith("_slc_multilooked_pwr_fil_geo_db_meta.tif"):
            matching_file = os.path.join(sub_folder_path, f)
            break

    if not matching_file:
        print(f"未找到与 {file_name} 匹配的目标文件")
        continue

    # 文件路径
    file_a_b_path = os.path.join(input_dir_a_b, file_name)
    # 确定保存路径，分别为 A 文件夹和 B 文件夹
    output_optical_dir = os.path.join(output_dir, "A")
    output_sar_dir = os.path.join(output_dir, "B")

    # 确保文件夹存在
    os.makedirs(output_optical_dir, exist_ok=True)
    os.makedirs(output_sar_dir, exist_ok=True)

    # 输出文件路径
    output_optical_path = os.path.join(output_optical_dir, file_name)
    output_sar_path = os.path.join(output_sar_dir, os.path.basename(matching_file))

    print("光学图像路径：", output_optical_path)
    print("SAR图像路径：", output_sar_path)

    # 打开两幅图像并获取掩膜
    with rasterio.open(file_a_b_path) as src1, rasterio.open(matching_file) as src2:
        # 获取掩膜（有效像素区域）
        mask1 = src1.dataset_mask() > 0  # 光学图像的有效区域掩膜
        mask2 = src2.dataset_mask() > 0  # SAR图像的有效区域掩膜

        # 将掩膜转换为几何对象
        shapes1 = [shape(geom) for geom, val in
                   rasterio.features.shapes(mask1.astype(np.uint8), transform=src1.transform) if val > 0]
        shapes2 = [shape(geom) for geom, val in
                   rasterio.features.shapes(mask2.astype(np.uint8), transform=src2.transform) if val > 0]

        # 合并掩膜区域为一个多边形
        union1 = unary_union(shapes1)
        union2 = unary_union(shapes2)

        # 计算重叠区域（直接使用几何对象的 intersection 方法）
        overlap = union1.intersection(union2)
        if overlap.is_empty:
            print(f"{file_name} 和 {matching_file} 没有重叠区域，跳过")
            continue

        # 裁剪光学图像
        cropped_image1, cropped_transform1 = mask(src1, [mapping(overlap)], crop=True)
        # 裁剪SAR图像
        cropped_image2, cropped_transform2 = mask(src2, [mapping(overlap)], crop=True)

        # 更新元数据并保存裁剪结果
        meta1 = src1.meta.copy()
        meta1.update({
            "driver": "GTiff",
            "height": cropped_image1.shape[1],
            "width": cropped_image1.shape[2],
            "transform": cropped_transform1
        })

        meta2 = src2.meta.copy()
        meta2.update({
            "driver": "GTiff",
            "height": cropped_image2.shape[1],
            "width": cropped_image2.shape[2],
            "transform": cropped_transform2
        })

        with rasterio.open(output_optical_path, "w", **meta1) as dest1:
            dest1.write(cropped_image1)
        with rasterio.open(output_sar_path, "w", **meta2) as dest2:
            dest2.write(cropped_image2)

    print(f"裁剪完成：{file_name} 和 {os.path.basename(matching_file)}")

print("所有裁剪任务完成！")
