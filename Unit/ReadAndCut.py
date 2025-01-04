import os
import rasterio
from rasterio.mask import mask
from rasterio.features import geometry_mask
import numpy as np
from shapely.geometry import shape, mapping
from shapely.ops import unary_union
import geopandas as gpd

# 设置基础输入和输出目录
base_input_dir = r"D:\0Program\Datasets\241120\Compare\TEMP\Four\Origin"
base_output_dir = r"D:\0Program\Datasets\241120\Compare\TEMP\Four\Cropped"

# 确保输出目录存在
os.makedirs(base_output_dir, exist_ok=True)

# 定义光学和SAR图像的路径
optical_image_path_reference = os.path.join(base_input_dir, "optical_549596_257631.tif")
sar_image_path_reference = os.path.join(base_input_dir, "sar_549596_257631.tif")
optical_image_path_target = os.path.join(base_input_dir, "O4.tif")
sar_image_path_target = os.path.join(base_input_dir, "S4.tif")

# 定义输出文件路径
cropped_optical_output_path = os.path.join(base_output_dir, "O8.tif")
cropped_sar_output_path = os.path.join(base_output_dir, "S8.tif")

# 打开参考图像（O4 和 S4）以获取掩膜
with rasterio.open(optical_image_path_reference) as ref_src1, rasterio.open(sar_image_path_reference) as ref_src2:
    # 获取参考图像的掩膜（有效像素区域）
    mask1 = ref_src1.dataset_mask() > 0  # 光学图像（O4）的有效区域掩膜
    mask2 = ref_src2.dataset_mask() > 0  # SAR图像（S4）的有效区域掩膜

    # 将掩膜转换为几何对象
    shapes1 = [shape(geom) for geom, val in rasterio.features.shapes(mask1.astype(np.uint8), transform=ref_src1.transform) if val > 0]
    shapes2 = [shape(geom) for geom, val in rasterio.features.shapes(mask2.astype(np.uint8), transform=ref_src2.transform) if val > 0]

    # 合并掩膜区域为一个多边形
    union1 = unary_union(shapes1)
    union2 = unary_union(shapes2)

    # 计算重叠区域（直接使用几何对象的 intersection 方法）
    overlap = union1.intersection(union2)
    print("重叠区域:", overlap)

    # 如果没有重叠，提示用户
    if overlap.is_empty:
        raise ValueError("参考图像（O4 和 S4）没有实际内容的重叠区域！")

    # 使用重叠区域裁剪目标图像（O5 和 S5）
    with rasterio.open(optical_image_path_target) as target_src1, rasterio.open(sar_image_path_target) as target_src2:
        # 裁剪光学图像（O5）
        cropped_image1, cropped_transform1 = mask(target_src1, [mapping(overlap)], crop=True)
        # 裁剪SAR图像（S5）
        cropped_image2, cropped_transform2 = mask(target_src2, [mapping(overlap)], crop=True)

        # 更新元数据并保存裁剪结果
        meta1 = target_src1.meta.copy()
        meta1.update({
            "driver": "GTiff",
            "height": cropped_image1.shape[1],
            "width": cropped_image1.shape[2],
            "transform": cropped_transform1
        })

        meta2 = target_src2.meta.copy()
        meta2.update({
            "driver": "GTiff",
            "height": cropped_image2.shape[1],
            "width": cropped_image2.shape[2],
            "transform": cropped_transform2
        })

        # 保存裁剪后的光学图像
        with rasterio.open(cropped_optical_output_path, "w", **meta1) as dest1:
            dest1.write(cropped_image1)

        # 保存裁剪后的SAR图像
        with rasterio.open(cropped_sar_output_path, "w", **meta2) as dest2:
            dest2.write(cropped_image2)

print("裁剪完成！裁剪结果已保存至：")
print(f"光学图像: {cropped_optical_output_path}")
print(f"SAR图像: {cropped_sar_output_path}")
