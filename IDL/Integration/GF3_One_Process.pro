PRO GF3_One_Process
  ; *************** 路径声明 ***************
  temp_directory = 'D:\0Program\Datasets\241120\temp_sarscape'
  input_import_folder = 'D:\0Program\Datasets\241120\xian2018\GF3_MYN_QPSI_027733_E109.2_N34.3_20211115_L1A_AHV_L10006044573\'
  output_import_folder = 'D:\0Program\Datasets\241120\outputs\import\'
  output_multilooking_folder = 'D:\0Program\Datasets\241120\outputs\multilooking_outputs\'
  output_filtered_folder = 'D:\0Program\Datasets\241120\outputs\filtered_outputs\'
  output_dem_folder = 'D:\0Program\Datasets\241120\outputs\dem_outputs\'
  output_geo_folder = 'D:\0Program\Datasets\241120\outputs\geo_outputs\'

  ; *************** 导入高分三号 ***************
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 设置临时目录（确保此目录存在）
  SARscape_Batch_Init, Temp_Directory=temporary_directory

  ; 加载 SARscape 扩展
  PRINT, '加载 SARscape 扩展...'
  a = sarmap_core_essentials(EXT_ONLY_SARMAP_CORE=1)

  ; 创建 SARscapeBatch 对象，设置模块为 ImportGaofen3
  PRINT, '为 ImportGaofen3 创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='ImportGaofen3')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF

  ; 使用 Manifest 方法显示 ImportGaofen3 模块的完整信息
  PRINT, '显示 ImportGaofen3 模块的完整信息...'
  seed = 'ImportGaofen3'
  oSB.Manifest, SEARCH=seed

  ; 列出模块的所有参数
  PRINT, '列出 模块参数...'
  oSB.ListParams

  ; 输入和输出文件夹
  input_folder = input_import_folder
  output_folder = output_import_folder

  ; 搜索 .meta.xml 文件
  PRINT, '正在搜索 GF3 的 .meta.xml 文件...'
  file_list = FILE_SEARCH(input_folder, '*.meta.xml')
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '在输入文件夹中未找到 .meta.xml 文件: ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并添加到批处理任务中
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_processed.tif'

    ; 设置输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('input_file_list', [input_file])
    ok = oSB.SetParam('output_file_list', [output_file])

    ; 列出当前设置的参数
    PRINT, '列出当前参数以进行验证...'
    oSB.ListParams

    ; 获取参数类型
    PRINT, '获取 output_file_list 的参数类型...'
    type = ''
    ok = oSB.GetParamType('output_file_list', type)
    IF NOT ok THEN BEGIN
      PRINT, '获取 output_file_list 参数类型失败'
    ENDIF ELSE BEGIN
      PRINT, 'output_file_list 的参数类型: ', type
    ENDELSE

    ; 验证参数是否设置正确
    PRINT, '验证文件的参数: ', input_file
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '文件参数验证失败: ', input_file
      CONTINUE
    ENDIF

    ; 执行任务
    PRINT, '执行文件的任务: ', input_file
    ok = oSB.Execute()
    IF NOT ok THEN BEGIN
      PRINT, '文件执行过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, '文件处理完成: ', input_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '批处理完成。'

  ; *************** 多视处理 ***************
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 设置临时目录（确保此目录存在）
  SARscape_Batch_Init, Temp_Directory=temporary_directory

  ; 加载 SARscape 扩展
  PRINT, '加载 SARscape 扩展...'
  a = sarmap_core_essentials(EXT_ONLY_SARMAP_CORE=1)

  ; 创建 SARscapeBatch 对象，设置模块为 BaseMultilooking
  PRINT, '为 BaseMultilooking 创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='BaseMultilooking')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF

  ; 输入和输出文件夹
  input_folder = output_import_folder ; 多视处理的输入数据文件路径
  output_folder = output_multilooking_folder ; 多视处理的输出路径

  ; 搜索输入文件（假设为导入后的文件名以 _slc 结尾）
  PRINT, '正在搜索多视处理的输入文件 (_slc)...'
  file_list = FILE_SEARCH(input_folder, '*_slc')  ; 改为处理 _slc 结尾的文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '在输入文件夹中未找到 _slc 结尾的文件: ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并添加到批处理任务中
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_multilooked_pwr'  ; 输出为 _pwr 格式

    ; 解析 SML 文件
    sml_file = input_file + '.sml'
    PRINT, '解析 SML 文件: ', sml_file
    pixel_spacing_az = -1
    pixel_spacing_rg = -1
    incidence_angle = -1

    IF FILE_TEST(sml_file) THEN BEGIN
      OPENR, unit, sml_file, /GET_LUN
      line = ''
      WHILE NOT EOF(unit) DO BEGIN
        READF, unit, line

        ; 提取 PixelSpacingAz 和 PixelSpacingRg
        IF STRPOS(line, '<PixelSpacingAz>') NE -1 THEN BEGIN
          var = line.Split('>')
          middle_part = var[1]
          pixel_spacing_azA = FLOAT(middle_part.Split('<'))
          pixel_spacing_az=pixel_spacing_azA[0]
          PRINT, 'Extracted PixelSpacingAz: ', pixel_spacing_az
        ENDIF

        IF STRPOS(line, '<PixelSpacingRg>') NE -1 THEN BEGIN
          var = line.Split('>')
          middle_part = var[1]
          pixel_spacing_rgA = FLOAT(middle_part.Split('<'))
          pixel_spacing_rg=pixel_spacing_rgA[0]
          PRINT, 'Extracted PixelSpacingRg: ', pixel_spacing_rg
        ENDIF

        ; 提取 IncidenceAngle
        IF STRPOS(line, '<IncidenceAngle>') NE -1 THEN BEGIN
          var = line.Split('>')
          middle_part = var[1]
          incidence_angleA = FLOAT(middle_part.Split('<'))
          incidence_angle=incidence_angleA[0]
          PRINT, 'Extracted IncidenceAngle: ', incidence_angle
        ENDIF
      ENDWHILE
      FREE_LUN, unit
    ENDIF

    ; 检查是否成功提取参数
    IF (pixel_spacing_az LT 0 OR pixel_spacing_rg LT 0 OR incidence_angle LT 0) THEN BEGIN
      PRINT, '从 SML 文件提取参数失败: ', sml_file
      CONTINUE
    ENDIF

    ; 计算多视因子
    ground_resolution = pixel_spacing_rg / SIN(!PI * incidence_angle / 180.0)
    range_multilook = CEIL(ground_resolution / pixel_spacing_rg)
    azimuth_multilook = CEIL(ground_resolution / pixel_spacing_az)
    PRINT, '自动计算的多视因子 - Range Looks: ', range_multilook, ', Azimuth Looks: ', azimuth_multilook

    ; 设置输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('input_file_list', [input_file])
    ok = oSB.SetParam('output_file_list', [output_file])

    ; 设置多视处理参数
    PRINT, '设置多视处理参数...'
    ok = oSB.SetParam('range_multilook', STRTRIM(range_multilook, 2))
    ok = oSB.SetParam('azimuth_multilook', STRTRIM(azimuth_multilook, 2))

    ; 设置多视方法为时域
    PRINT, '设置多视处理方法为时域...'
    ok = oSB.SetParam('multilook_method', 'time_domain')

    ; 验证参数是否设置正确
    PRINT, '验证文件的参数: ', input_file
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '文件参数验证失败: ', input_file
      CONTINUE
    ENDIF

    ; 执行任务
    PRINT, '执行文件的任务: ', input_file
    ok = oSB.Execute()
    IF NOT ok THEN BEGIN
      PRINT, '文件执行过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, '文件处理完成: ', input_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '多视处理批处理完成。'

  ; *************** 单通道强度数据滤波 ***************
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 设置临时目录（确保此目录存在）
  SARscape_Batch_Init, Temp_Directory=temporary_directory

  ; 加载 SARscape 扩展
  PRINT, '加载 SARscape 扩展...'
  a = sarmap_core_essentials(EXT_ONLY_SARMAP_CORE=1)

  ; 创建 SARscapeBatch 对象，设置模块为 DespeckleConventionalSingle
  PRINT, '为 DespeckleConventionalSingle 创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='DespeckleConventionalSingle')

  ; 检查对象是否创建成功
  IF (~OBJ_VALID(oSB)) THEN BEGIN
    PRINT, '错误: SARscape 批处理对象初始化失败。'
    SARscape_Batch_Exit
    RETURN
  ENDIF

  ; 列出模块的所有参数
  PRINT, '列出模块参数...'
  oSB.ListParams

  ; 输入和输出文件夹
  input_folder = output_multilooking_folder ; 输入数据文件路径
  output_folder = output_filtered_folder ; 输出数据文件路径

  ; 搜索输入文件（假设为导入后的文件名以 _pwr 结尾）
  PRINT, '正在搜索滤波处理的输入文件 (_pwr)...'
  file_list = FILE_SEARCH(input_folder, '*_pwr')  ; 改为处理 _pwr 结尾的文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '在输入文件夹中未找到 _pwr 结尾的文件: ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并添加到批处理任务中
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_fil'

    ; 设置输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('input_file_list', [input_file])
    ok = oSB.SetParam('output_file_list', [output_file])

    ; 设置滤波参数
    PRINT, '设置滤波参数...'
    ok = oSB.SetParam('filt_type', 'Refined Lee') ; 滤波器类型：Refined Lee
    ok = oSB.SetParam('rows_window_number', 5) ; 窗口大小（行）
    ok = oSB.SetParam('cols_window_number', 5) ; 窗口大小（列）

    ; 验证参数是否设置正确
    PRINT, '验证文件的参数: ', input_file
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '文件参数验证失败: ', input_file
      CONTINUE
    ENDIF

    ; 执行任务
    PRINT, '执行文件的任务: ', input_file
    ok = oSB.Execute()
    IF NOT ok THEN BEGIN
      PRINT, '文件执行过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, '文件处理完成: ', input_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '单通道滤波批处理完成。'

  ; *************** DEM ***************
  ; 初始化 ENVI 和 SARscape 批处理模式
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT

  ; 创建 SARscapeBatch 对象，用于 GMTED DEM 提取
  PRINT, '为 GMTED2010 DEM 提取创建 SARscape 批处理对象...'
  oSB = obj_new('SARscapeBatch', Module='ToolsDEMExtractionGmted')

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
  input_folder = output_filtered_folder  ; 输入文件夹
  output_folder = output_dem_folder      ; DEM 输出文件夹

  ; 搜索 _fil 文件作为输入
  PRINT, '正在搜索 DEM 提取的输入文件 (_fil)...'
  file_list = FILE_SEARCH(input_folder, '*_fil')  ; 搜索所有 _fil 文件
  IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
    PRINT, '未找到输入文件 (_fil): ', input_folder
    RETURN
  ENDIF

  ; 遍历文件列表并逐一处理
  FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
    input_file = file_list[i]
    output_file = output_folder + FILE_BASENAME(input_file) + '_dem'  ; DEM 输出文件名

    ; 设置 DEM 输入和输出参数
    PRINT, '正在处理文件: ', input_file
    ok = oSB.SetParam('reference_sr_image_val', [input_file])  ; 设置输入文件
    ok = oSB.SetParam('output_file_dem_val', [output_file])    ; 设置输出文件路径
    ok = oSB.SetParam('grid_size', 450.0)                     ; 网格大小为 450 米

    ; 设置投影参数
    PRINT, '设置投影参数...'
    ok = oSB.SetParam('ocs_state', 'UTM-GLOBAL')         ; 投影方式
    ok = oSB.SetParam('ocs_hemisphere', 'NORTH')         ; 北半球
    ok = oSB.SetParam('ocs_projection', 'UTM')           ; UTM 投影
    ok = oSB.SetParam('ocs_zone', '49')                  ; UTM Zone 49
    ok = oSB.SetParam('ocs_ellipsoid', 'WGS84')          ; 椭球为 WGS84
    ok = oSB.SetParam('ocs_reference_height', 0.0)       ; 基准高程

    ; 验证设置的参数
    PRINT, '验证参数设置...'
    oSB.ListParams
    ok = oSB.VerifyParams()
    IF NOT ok THEN BEGIN
      PRINT, '参数验证失败，请检查输入设置: ', input_file
      CONTINUE
    ENDIF

    ; 执行 DEM 提取任务
    PRINT, '执行 DEM 提取任务: ', input_file
    ok = oSB.Execute()
    IF NOT ok THEN BEGIN
      PRINT, 'DEM 提取过程中发生错误: ', input_file
      CONTINUE
    ENDIF

    PRINT, 'DEM 提取完成，文件保存在: ', output_file
  ENDFOR

  ; 释放对象并退出批处理模式
  obj_destroy, oSB
  SARscape_Batch_Exit
  PRINT, '所有 DEM 提取任务已完成。'

  ; *************** 地理编码和辐射定标 ***************
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
  input_folder = output_filtered_folder  ; 滤波文件输入路径
  dem_folder = output_dem_folder        ; DEM 文件路径
  output_folder = output_geo_folder     ; 地理编码输出路径

  ; 搜索 _fil 文件作为主输入
  PRINT, '正在搜索地理编码的输入文件 (_fil)...'
  file_list = FILE_SEARCH(input_folder, '*_fil')  ; 搜索所有 _fil 文件
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