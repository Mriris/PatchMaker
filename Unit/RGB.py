#不需要该步骤

import rasterio
from rasterio import plot
from PIL import Image

# 输入文件路径
input_file = r"D:/0Program/Datasets/241120/Compare/TEMP/Four/Cropped/cropped_sar_image.tif"
output_file_rgb = r"D:/0Program/Datasets/241120/Compare/TEMP/Four/Cropped/cropped_sar_image_rgb.tif"

# 打开图像并提取波段
with rasterio.open(input_file) as src:
    # 检查波段数
    print(f"波段数: {src.count}")

    # 如果是多波段，提取前3个波段（假设为 RGB）
    if src.count >= 3:
        r = src.read(1)
        g = src.read(2)
        b = src.read(3)

        # 创建 RGB 图像
        rgb_image = Image.fromarray((plot.reshape_as_image([r, g, b])).astype('uint8'))
        rgb_image.save(output_file_rgb)
        print(f"RGB 图像已保存至: {output_file_rgb}")
    else:
        # 如果是单波段，直接保存为灰度图
        gray_image = Image.fromarray(src.read(1).astype('uint8'))
        gray_image.save(output_file_rgb)
        print(f"灰度图像已保存至: {output_file_rgb}")
