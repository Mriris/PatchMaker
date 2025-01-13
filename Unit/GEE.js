// 定义感兴趣区域（ROI）
var roi = ee.Geometry.Rectangle([
  384100.6489999999757856, 4319736.0499999998137355, // 左下角
  414580.6489999999757856, 4346080.0499999998137355  // 右上角
]);

// 获取 ROI 的边界坐标
var bounds = roi.bounds().coordinates().get(0).getInfo(); // 使用 getInfo() 将 ee.List 转换为 JavaScript 数组
var xMin = bounds[0][0]; // 左下角经度
var yMin = bounds[0][1]; // 左下角纬度
var xMax = bounds[2][0]; // 右上角经度
var yMax = bounds[2][1]; // 右上角纬度

// 定义分块数
var numX = 4; // 水平方向分为 4 块
var numY = 4; // 垂直方向分为 4 块

// 计算每块的宽度和高度
var xStep = (xMax - xMin) / numX;
var yStep = (yMax - yMin) / numY;

// Sentinel-2 数据
var collection = ee.ImageCollection('COPERNICUS/S2')
                  .filterBounds(roi)
                  .filterDate('2018-03-01', '2018-04-30')
                  .sort('system:time_start');

// 获取最接近目标日期的影像
var targetDate = ee.Date('2018-03-31');
var closestImage = collection.map(function(image) {
  var diff = image.date().difference(targetDate, 'day').abs();
  return image.set('time_diff', diff);
}).sort('time_diff').first();

// 提取 RGB 波段
var rgbImage = closestImage.select(['B4', 'B3', 'B2']); // 红、绿、蓝波段

// 定义导出函数
function exportTile(i, j) {
  var x0 = xMin + xStep * i;       // 块的左边界
  var x1 = x0 + xStep;             // 块的右边界
  var y0 = yMin + yStep * j;       // 块的下边界
  var y1 = y0 + yStep;             // 块的上边界

  var tile = ee.Geometry.Rectangle([x0, y0, x1, y1]); // 定义子块
  var clippedTile = rgbImage.clip(tile);              // 裁剪影像

  Export.image.toDrive({
    image: clippedTile,
    description: 'Sentinel2_20180331_tile_' + i + '_' + j,
    scale: 10,
    region: tile,
    crs: 'EPSG:32633', // 替换为您需要的坐标系
    fileFormat: 'GeoTIFF',
    maxPixels: 1e13
  });
}

// 遍历所有子块并导出
for (var i = 0; i < numX; i++) {
  for (var j = 0; j < numY; j++) {
    exportTile(i, j);
  }
}
