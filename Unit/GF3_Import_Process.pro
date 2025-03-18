PRO GF3_Import_Process
    ; 初始化 ENVI 和 SARscape 批处理模式
    PRINT, '启动 ENVI 并初始化 SARscape 批处理模式...'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT

    ; 设置临时目录（确保此目录存在）
    temporary_directory = 'D:\0Program\Datasets\241120\temp_sarscape'
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
    PRINT, '列出 ImportGaofen3 模块的参数...'
    oSB.ListParams

    ; 输入和输出文件夹
    input_folder = 'D:\0Program\Datasets\241120\xian2018\GF3_MYN_QPSI_027733_E109.2_N34.3_20211115_L1A_AHV_L10006044573\' ; 替换为 GF3 数据文件的实际路径
    output_folder = 'D:\0Program\Datasets\241120\outputs\import\' ; 替换为输出结果的路径

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
        ok = oSB.ExecuteProgress()
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
END
