PRO GF3_Pipeline_Process
  ; *************** 路径声明 ***************
;  base_input_folder = 'D:\0Program\Datasets\241120\inputs\'
;  base_output_folder = 'D:\0Program\Datasets\241120\outputs\'
;  temp_directory = 'D:\0Program\Datasets\241120\temp_sarscape'
  base_input_folder = 'D:\0Program\Datasets\241120\inputs\'
  base_output_folder = 'D:\0Program\Datasets\241120\outputs\'
  temp_directory = 'D:\0Program\Datasets\241120\temp_sarscape'

  ; *************** 初始化 ***************
  PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT
  SARscape_Batch_Init, Temp_Directory=temp_directory
  PRINT, 'SARscape 初始化完成。'

  ; *************** 遍历地名文件夹 ***************
  location_folders = FILE_SEARCH(base_input_folder + '*', /MARK_DIRECTORY)  ; 搜索所有地名文件夹
  IF N_ELEMENTS(location_folders) EQ 0 THEN BEGIN
    PRINT, '未找到任何地名文件夹: ', base_input_folder
    RETURN
  ENDIF
  ; 输出所有地名文件夹
  PRINT, '找到以下地名文件夹:'
  FOR i = 0, N_ELEMENTS(location_folders) - 1 DO BEGIN
    PRINT, location_folders[i]
  ENDFOR

  ; 遍历地名文件夹
  FOR loc_idx = 0, N_ELEMENTS(location_folders) - 1 DO BEGIN
    location_folder = location_folders[loc_idx]
    location_name = FILE_BASENAME(location_folder)

    ; 创建对应的输出地名文件夹
    output_location_folder = base_output_folder + location_name + '\'
    IF NOT FILE_TEST(output_location_folder, /DIRECTORY) THEN FILE_MKDIR, output_location_folder
    PRINT, '地名输出文件夹: ', output_location_folder

    ; *************** 遍历数据集文件夹 ***************
    dataset_folders = FILE_SEARCH(location_folder + '*', /MARK_DIRECTORY)  ; 搜索地名文件夹中的数据集文件夹
    IF N_ELEMENTS(dataset_folders) EQ 0 THEN BEGIN
      PRINT, '未找到数据集文件夹: ', location_folder
      CONTINUE
    ENDIF

    ; 遍历数据集文件夹
    FOR ds_idx = 0, N_ELEMENTS(dataset_folders) - 1 DO BEGIN
      dataset_folder = dataset_folders[ds_idx]
      dataset_name = FILE_BASENAME(dataset_folder)

      ; 提取文件夹名中的经度并计算 UTM Zone
      tokens = STRSPLIT(dataset_name, '_', /EXTRACT)
      PRINT, '解析的文件夹名: ', dataset_name
      IF N_ELEMENTS(tokens) GE 5 THEN BEGIN
        ; 提取第四部分并去掉首字母
        longitude_string = tokens[4]
        PRINT, '提取的经度字符串: ', longitude_string
        longitude_string = STRMID(longitude_string, 1)  ; 去掉首字母
        ;        PRINT, '去掉首字母后的经度字符串: ', longitude_string

        ; 转换为浮点数
        longitude = FLOAT(longitude_string)
        ;        PRINT, '转换后的经度值: ', longitude

        ; 计算 UTM Zone
        utm_zone = FIX((longitude / 6) + 31)  ; 使用 FIX 将结果转换为整数
        PRINT, '计算的 UTM Zone: ', utm_zone
      ENDIF ELSE BEGIN
        PRINT, '无法解析文件夹名，缺少足够的部分: ', dataset_name
        RETURN
      ENDELSE

      ; 创建对应的输出数据集文件夹（地名文件夹下，根据数据集文件夹名的后六位创建新文件夹）
      output_dataset_suffix = STRMID(dataset_name, STRLEN(dataset_name) - 6, 6)
      output_dataset_folder = output_location_folder + output_dataset_suffix + '\'
      IF NOT FILE_TEST(output_dataset_folder, /DIRECTORY) THEN FILE_MKDIR, output_dataset_folder
      PRINT, '数据集输出文件夹: ', output_dataset_folder

      ; *************** 处理当前数据集文件夹内的数据 ***************
      ; 搜索 .meta.xml 文件
      file_list = FILE_SEARCH(dataset_folder + '*.meta.xml')
      IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
        PRINT, '在数据集文件夹中未找到 .meta.xml 文件: ', dataset_folder
        CONTINUE
      ENDIF

      ; 遍历文件列表并处理
      FOR k = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
        input_file = file_list[k]
        output_file = output_dataset_folder + FILE_BASENAME(input_file) + '_processed.tif'

        ; 创建 SARscapeBatch 对象
        oSB = OBJ_NEW('SARscapeBatch', Module='ImportGaofen3')
        IF (~OBJ_VALID(oSB)) THEN BEGIN
          PRINT, '错误: SARscape 批处理对象初始化失败。'
          SARscape_Batch_Exit
          RETURN
        ENDIF

        ; 设置参数并执行任务
        PRINT, '正在处理文件: ', input_file
        ok = oSB.SetParam('input_file_list', [input_file])
        ok = oSB.SetParam('output_file_list', [output_file])

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
        PRINT, '执行文件的任务: ', input_file
        ok = oSB.Execute()
        IF NOT ok THEN BEGIN
          PRINT, '文件执行过程中发生错误: ', input_file
          CONTINUE
        ENDIF
        PRINT, '文件处理完成: ', input_file

        ; 释放对象
        OBJ_DESTROY, oSB
      ENDFOR



      ; *************** 多视处理 ***************
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
      input_folder = output_dataset_folder ; 多视处理的输入数据文件路径
      output_folder = output_dataset_folder ; 多视处理的输出路径

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
      PRINT, '多视处理批处理完成。'

      ; *************** 单通道强度数据滤波 ***************
      ; 创建 SARscapeBatch 对象，设置模块为 DespeckleConventionalSingle
      PRINT, '为 DespeckleConventionalSingle 创建 SARscape 批处理对象...'
      oSB = obj_new('SARscapeBatch', Module='DespeckleConventionalSingle')

      ; 检查对象是否创建成功
      IF (~OBJ_VALID(oSB)) THEN BEGIN
        PRINT, '错误: SARscape 批处理对象初始化失败。'
        SARscape_Batch_Exit
        RETURN
      ENDIF

      ;      ; 列出模块的所有参数
      ;      PRINT, '列出模块参数...'
      ;      oSB.ListParams

      ; 输入和输出文件夹
      input_folder = output_dataset_folder ; 输入数据文件路径
      output_folder = output_dataset_folder ; 输出数据文件路径

      ; 搜索输入文件（导入后的文件名以 _pwr 结尾）
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
      PRINT, '单通道滤波批处理完成。'

      ; *************** DEM ***************
      ; 创建 SARscapeBatch 对象，用于 GMTED DEM 提取
      PRINT, '为 GMTED2010 DEM 提取创建 SARscape 批处理对象...'
      oSB = obj_new('SARscapeBatch', Module='ToolsDEMExtractionGmted')

      ; 检查对象是否创建成功
      IF (~OBJ_VALID(oSB)) THEN BEGIN
        PRINT, '错误: SARscape 批处理对象初始化失败。'
        SARscape_Batch_Exit
        RETURN
      ENDIF

      ;      ; 列出模块的所有参数
      ;      PRINT, '列出模块参数...'
      ;      oSB.ListParams

      ; 设置输入和输出路径
      input_folder = output_dataset_folder  ; 输入文件夹
      output_folder = output_dataset_folder      ; DEM 输出文件夹

      ; 搜索 _fil 文件作为输入
      PRINT, '正在搜索 DEM 提取的输入文件 (_fil)...'
      file_list = FILE_SEARCH(input_folder, '*_fil')  ; 搜索所有 _fil 文件
      IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
        PRINT, '未找到输入文件 (_fil): ', input_folder
        RETURN
      ENDIF

      ; 遍历文件列表并逐一处理
      ;      FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
      ;        input_file = file_list[i]
      input_file = file_list[0]
      ;        output_file = output_folder + FILE_BASENAME(input_file) + '_dem'  ; DEM 输出文件名
      output_file = output_dataset_folder + 'single_dem'  ; 统一生成一个 DEM 文件

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
      ok = oSB.SetParam('ocs_zone', utm_zone)              ; UTM Zone
      ok = oSB.SetParam('ocs_ellipsoid', 'WGS84')          ; 椭球为 WGS84
      ok = oSB.SetParam('ocs_reference_height', 0.0)       ; 基准高程

      ; 验证设置的参数
      PRINT, '验证参数设置...'
      ;        oSB.ListParams
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
      ;      ENDFOR

      ; 释放对象并退出批处理模式
      obj_destroy, oSB
      PRINT, '所有 DEM 提取任务已完成。'

      ; *************** 地理编码和辐射定标 ***************
      ; 创建 SARscapeBatch 对象，用于地理编码和辐射定标
      PRINT, '为地理编码和辐射定标创建 SARscape 批处理对象...'
      oSB = obj_new('SARscapeBatch', Module='BasicGeocoding')

      ; 检查对象是否创建成功
      IF (~OBJ_VALID(oSB)) THEN BEGIN
        PRINT, '错误: SARscape 批处理对象初始化失败。'
        SARscape_Batch_Exit
        RETURN
      ENDIF

      ;      ; 列出模块的所有参数
      ;      PRINT, '列出模块参数...'
      ;      oSB.ListParams

      ; 设置输入和输出路径
      input_folder = output_dataset_folder  ; 滤波文件输入路径
      dem_folder = output_dataset_folder        ; DEM 文件路径
      output_folder = output_dataset_folder     ; 地理编码输出路径

      ; 搜索 _fil 文件作为主输入
      PRINT, '正在搜索地理编码的输入文件 (_fil)...'
      file_list = FILE_SEARCH(input_folder, '*_fil')  ; 搜索所有 _fil 文件
      IF N_ELEMENTS(file_list) EQ 0 THEN BEGIN
        PRINT, '未找到输入文件 (_fil): ', input_folder
        RETURN
      ENDIF
      dem_file = output_dataset_folder + 'single_dem'
      ; 遍历文件列表并逐一处理
      FOR i = 0, N_ELEMENTS(file_list) - 1 DO BEGIN
        input_file = file_list[i]
        ;        dem_file = dem_folder + FILE_BASENAME(input_file) + '_dem'  ; 对应的 DEM 文件
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
        ok = oSB.SetParam('ocs_zone', utm_zone)              ; UTM Zone
        ok = oSB.SetParam('ocs_ellipsoid', 'WGS84')          ; 椭球为 WGS84
        ok = oSB.SetParam('ocs_reference_height', 0.0)       ; 基准高程

        ; 验证参数设置
        PRINT, '验证参数设置...'
        ;        oSB.ListParams
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
      PRINT, '地理编码任务已完成。'

      ; *************** db生成转meta ***************
      ; 设置输入文件夹和 meta 文件路径
      input_folder = output_dataset_folder  ; 包含 _db 文件的目录
      output_meta_file = output_dataset_folder + FILE_BASENAME(input_file) + '_geo_db_meta'

      ; 搜索所有 _db 文件
      PRINT, '正在搜索 _db 文件...'
      db_files = FILE_SEARCH(input_folder, '*_db')  ; 搜索所有以 _db 结尾的文件
      IF N_ELEMENTS(db_files) EQ 0 THEN BEGIN
        PRINT, '未找到任何 _db 文件: ', input_folder
        RETURN
      ENDIF

      ; 倒序文件列表
      db_files = REVERSE(db_files)

      ; 打开文件写入
      PRINT, '正在生成 meta 文件: ', output_meta_file
      OPENW, unit, output_meta_file, /GET_LUN
      PRINTF, unit, 'ENVI META FILE'

      ; 初始化 ENVI 环境
      PRINT, '启动 ENVI 环境以读取文件信息...'
      e = ENVI(/HEADLESS)  ; 启动 ENVI
      IF NOT OBJ_VALID(e) THEN BEGIN
        PRINT, 'ENVI 初始化失败。'
        FREE_LUN, unit
        RETURN
      ENDIF

      ; 遍历所有 _db 文件
      FOR i = 0, N_ELEMENTS(db_files) - 1 DO BEGIN
        db_file = db_files[i]
        PRINT, '处理文件: ', db_file

        ; 打开 _db 文件
        raster = e.OpenRaster(db_file)
        IF NOT OBJ_VALID(raster) THEN BEGIN
          PRINT, '加载文件失败: ', db_file
          CONTINUE
        ENDIF

        ; 获取波段数、列数和行数
        bands = raster.NBANDS
        rows = raster.NCOLUMNS
        cols = raster.NROWS

        ; 写入 meta 文件内容（格式化）
        short_filename = FILE_BASENAME(db_file)  ; 提取短文件名
        PRINTF, unit, 'File : ', short_filename
        PRINTF, unit, 'Bands: ', STRING(bands, FORMAT='(I1)')  ; 确保波段数格式为整齐的单行
        PRINTF, unit, 'Dims : 1-', STRING(rows, FORMAT='(I0)'), ',1-', STRING(cols, FORMAT='(I0)')
        PRINTF, unit, ''  ; 空行分隔每个文件的信息

        ; 释放 raster 对象
        OBJ_DESTROY, raster
      ENDFOR

      ; 关闭文件和 ENVI 环境
      FREE_LUN, unit
      PRINT, 'Meta 文件生成完成: ', output_meta_file



      ; *************** meta转tif ***************
      ; 定义输入和输出路径
      meta_file = output_meta_file
      output_tiff_file = output_meta_file+'.tif'

      ; 检查输入文件是否存在
      IF NOT FILE_TEST(meta_file) THEN BEGIN
        PRINT, '输入文件不存在: ', meta_file
        RETURN
      ENDIF

      ; 加载输入 raster
      PRINT, '加载输入文件: ', meta_file
      Raster = e.OpenRaster(meta_file)
      IF NOT OBJ_VALID(Raster) THEN BEGIN
        PRINT, '加载输入文件失败: ', meta_file
        RETURN
      ENDIF

      ; 获取任务
      PRINT, '获取 ExportRasterToTIFF 任务...'
      Task = ENVITask('ExportRasterToTIFF')
      IF NOT OBJ_VALID(Task) THEN BEGIN
        PRINT, '获取任务失败。'
        RETURN
      ENDIF

      ; 设置任务参数
      PRINT, '设置任务参数...'
      Task.INPUT_RASTER = Raster  ; 设置输入 raster
      Task.OUTPUT_RASTER_URI = output_tiff_file  ; 设置输出路径
      Task.DATA_IGNORE_VALUE = 0  ; 设置无效值（可根据需求调整）

      ; 执行任务
      PRINT, '执行任务...'
      Task.Execute

      ; 验证输出
      IF FILE_TEST(output_tiff_file) THEN BEGIN
        PRINT, '导出完成，文件保存至: ', output_tiff_file
      ENDIF ELSE BEGIN
        PRINT, '导出失败，请检查配置。'
      ENDELSE

      ; 释放资源
      OBJ_DESTROY, Raster
      PRINT, '任务完成。'


    ENDFOR
  ENDFOR

  ; *************** 结束 ***************
  SARscape_Batch_Exit
  PRINT, '所有任务完成。'
END
