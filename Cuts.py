import os
import rasterio
from rasterio.mask import mask
from rasterio.features import shapes
import numpy as np
from shapely.geometry import shape, mapping
from shapely.ops import unary_union
import geopandas as gpd

# 设置输入和输出目录
base_input_dir_1 = r"C:\0Program\Datasets\241120\Compare\Datas\tif_A"  # 第一个文件夹（多个x_y.tif）
base_input_dir_2 = r"C:\0Program\Datasets\241120\Compare\Datas\B"  # 参考用的文件夹（y.tif）
base_input_dir_3 = r"C:\0Program\Datasets\241120\Compare\Datas\tif_B"  # 第三个文件夹（y.tif，与第二个文件夹文件名相同）
base_output_dir = r"C:\0Program\Datasets\241120\Compare\Datas\out"  # 输出文件夹

# 确保输出目录存在
os.makedirs(base_output_dir, exist_ok=True)

# 获取第一个文件夹（x_y.tif）中的所有文件
input_files_1 = [f for f in os.listdir(base_input_dir_1) if f.endswith('.tif')]

# 遍历第一个文件夹的文件
for filename in input_files_1:
    # 从文件名中提取y部分
    y_value = filename.split('_')[1].split('.')[0]

    # 构建第二个和第三个文件夹中对应的文件路径
    second_image_path = os.path.join(base_input_dir_2, f"{y_value}.tif")
    third_image_path = os.path.join(base_input_dir_3, f"{y_value}.tif")

    if not os.path.exists(second_image_path):
        print(f"未找到对应的y值文件: {second_image_path}")
        continue
    if not os.path.exists(third_image_path):
        print(f"未找到对应的y值文件: {third_image_path}")
        continue

    # 定义影像的路径
    first_image_path = os.path.join(base_input_dir_1, filename)

    # 打开三幅图像并获取重叠区域
    with rasterio.open(first_image_path) as src1, rasterio.open(second_image_path) as src2, rasterio.open(third_image_path) as src3:
        # 获取有效像素掩膜（>0表示有效）
        mask1 = src1.dataset_mask() > 0  # 第一幅图像的有效区域
        mask2 = src2.dataset_mask() > 0  # 第二幅图像的有效区域
        mask3 = src3.dataset_mask() > 0  # 第三幅图像的有效区域

        # 将掩膜转换为几何对象
        shapes1 = [shape(geom) for geom, val in shapes(mask1.astype(np.uint8), transform=src1.transform) if val > 0]
        shapes2 = [shape(geom) for geom, val in shapes(mask2.astype(np.uint8), transform=src2.transform) if val > 0]

        # 计算各自的有效区域
        union1 = unary_union(shapes1)  # 第一幅图像的有效区域
        union2 = unary_union(shapes2)  # 第二幅图像的有效区域

        # 计算两幅影像的重叠区域
        overlap = union1.intersection(union2)

        # 如果没有重叠区域，则跳过该图像
        if overlap.is_empty:
            print(f"没有重叠区域，跳过文件: {filename}")
            continue

        # 转换为GeoDataFrame（便于检查）
        overlap_gdf = gpd.GeoDataFrame({"geometry": [overlap]}, crs=src1.crs)

        # 裁剪图像
        cropped_image1, cropped_transform1 = mask(src1, [mapping(overlap)], crop=True)
        cropped_image3, cropped_transform3 = mask(src3, [mapping(overlap)], crop=True)

        # 更新影像的元数据
        meta1 = src1.meta.copy()
        meta1.update({
            "driver": "GTiff",
            "height": cropped_image1.shape[1],
            "width": cropped_image1.shape[2],
            "transform": cropped_transform1
        })

        meta3 = src3.meta.copy()
        meta3.update({
            "driver": "GTiff",
            "height": cropped_image3.shape[1],
            "width": cropped_image3.shape[2],
            "transform": cropped_transform3
        })

        # 定义输出路径
        output_image_1 = os.path.join(base_output_dir, f"{filename.split('.')[0]}_A.tif")
        output_image_3 = os.path.join(base_output_dir, f"{filename.split('.')[0]}_B.tif")

        # 保存裁剪后的图像
        with rasterio.open(output_image_1, "w", **meta1) as dest1:
            dest1.write(cropped_image1)

        with rasterio.open(output_image_3, "w", **meta3) as dest3:
            dest3.write(cropped_image3)

        print(f"裁剪完成！文件已保存至：{output_image_1} 和 {output_image_3}")
