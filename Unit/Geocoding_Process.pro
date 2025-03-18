PRO Geocoding_Process
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 创建 SARscapeBatch 对象，用于地理编码和辐射定标
  PRINT, '为地理编码和辐射定标创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='BasicGeocoding')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF

  ; 列出模块的所有参数
  PRINT, '列出模块参数...'
  oSB.ListParams

  ; 设置输入和输出路径
  input_folder = 'D:\0Program\Datasets\241120\outputs\filtered_outputs\'  ; 滤波文件输入路径
  dem_folder = 'D:\0Program\Datasets\241120\outputs\dem_outputs\'        ; DEM 文件路径
  output_folder = 'D:\0Program\Datasets\241120\outputs\geo_outputs\'     ; 地理编码输出路径

  ; 搜索 `_fil` 文件作为主输入
  PRINT, '正在搜索地理编码的输入文件 (_fil)...'
  file_list = FILE_SEARCH(input_folder, '*_fil')  ; 搜索所有 `_fil` 文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '未找到输入文件 (_fil): ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并逐一处理
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    dem_file = dem_folder + FILE_BASENAME(input_file) + '_dem'  ; 对应的 DEM 文件
    output_file = output_folder + FILE_BASENAME(input_file) + '_geo'  ; 地理编码输出文件

    ; 检查 DEM 文件是否存在
    IF NOT FILE_TEST(dem_file) THEN BEGIN
      PRINT, '对应的 DEM 文件不存在: ', dem_file
      CONTINUE
    ENDIF

    ; 设置地理编码输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('input_file_list', [input_file])  ; 设置主输入文件
    ok = oSB.SetParam('dem_file_name', [dem_file])      ; 设置 DEM 文件
    ok = oSB.SetParam('output_file_list', [output_file]) ; 设置输出文件路径
    ok = oSB.SetParam('geocode_grid_size_x', 8)         ; 像元大小 X
    ok = oSB.SetParam('geocode_grid_size_y', 8)         ; 像元大小 Y

    ; 设置辐射定标参数
    PRINT, '设置辐射定标参数...'
    ok = oSB.SetParam('calibration_flag', 'True')                     ; 启用辐射定标
    ok = oSB.SetParam('geo_scattering_area_method', 'Local Incidence Angle') ; 散射面
    ok = oSB.SetParam('rad_normalization_flag', 'False')              ; 辐射归一化
    ok = oSB.SetParam('generate_layovershadow_flag', 'False')         ; 叠掩/阴影
    ok = oSB.SetParam('generate_lia_flag', 'False')                   ; 局部入射角
    ok = oSB.SetParam('generate_k_flag', 'False')                     ; 不生成原始几何
    ok = oSB.SetParam('output_type', 'output_type_db')                ; 输出类型设置为 db


    ; 设置投影参数
    PRINT, '设置投影参数...'
    ok = oSB.SetParam('ocs_state', 'UTM-GLOBAL')         ; 投影方式
    ok = oSB.SetParam('ocs_hemisphere', 'NORTH')         ; 北半球
    ok = oSB.SetParam('ocs_projection', 'UTM')           ; UTM 投影
    ok = oSB.SetParam('ocs_zone', '49')                  ; UTM Zone 49
    ok = oSB.SetParam('ocs_ellipsoid', 'WGS84')          ; 椭球为 WGS84
    ok = oSB.SetParam('ocs_reference_height', 0.0)       ; 基准高程

    ; 验证参数设置
    PRINT, '验证参数设置...'
    oSB.ListParams
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '参数验证失败，请检查输入设置: ', input_file
      CONTINUE
    ENDIF

    ; 执行地理编码任务
    PRINT, '执行地理编码任务: ', input_file
    ok = oSB.Execute()
    IF NOT ok THEN BEGIN
      PRINT, '地理编码过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, '地理编码完成，文件保存在: ', output_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '所有地理编码任务已完成。'
END
