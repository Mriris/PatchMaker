var startDate = ee.Date('2022-01-01'); // set start time for analysis
var endDate = ee.Date('2022-12-31'); // set end time for analysis
var nDays = ee.Number(endDate.difference(startDate,'day')).round();
// coordinate Arpat Ponte alle Mosse
//var point = ee.Geometry.Point([11.230520538799576, 43.78480193916678]);
// Signa 11.097849 43.793234
//https://www.arpat.toscana.it/temi-ambientali/aria/qualita-aria/rete_monitoraggio/scheda_stazione/FI-SIGNA
var point = ee.Geometry.Point([11.097849, 43.793234]);
Map.setCenter(11.097849, 43.793234,14);
var chirps = ee.ImageCollection('COPERNICUS/S5P/NRTI/L3_O3')
            .select('O3_column_number_density')
            .filterBounds(point)
            .filterDate(startDate, endDate)
            .map(function(image){return image.clip(point)}) ;

//这个关键地方，，是需要我们建立一个时序，然后获取每一天的值，这里最主要的时间函数的运用，以及影像系统时间的设定
var byday = ee.ImageCollection(
  // map over each day
  ee.List.sequence(0,nDays).map(function (n) {
    var ini = startDate.advance(n,'day');
    // advance just one day
    var end = ini.advance(1,'day');
    return chirps.filterDate(ini,end)
                .select(0).mean()
                .set('system:time_start', ini);
}));
// plot full time series
print(
  ui.Chart.image.series({
    imageCollection: byday,
    region: point,
    scale: 1
  }).setOptions({title: 'O3 Signa 2020 mol/m2'})
);
Export.table.toDrive({
        collection: chirps,
        description: 'O3',
    fileNamePrefix: 'O3',
    fileFormat: 'CSV'
    });