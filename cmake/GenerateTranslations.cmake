# Compiles the translation sources into the files the launcher loads at runtime.
#
# Run through `cmake -P`, expects:
#   TRANSLATIONS_SOURCE_DIR  directory holding the .ts files
#   TRANSLATIONS_OUTPUT_DIR  directory to write .qm, index_v2.json and the .qrc into
#   LRELEASE_BIN             path to lrelease

if(NOT DEFINED TRANSLATIONS_SOURCE_DIR OR NOT DEFINED TRANSLATIONS_OUTPUT_DIR OR NOT DEFINED LRELEASE_BIN)
    message(FATAL_ERROR "TRANSLATIONS_SOURCE_DIR, TRANSLATIONS_OUTPUT_DIR and LRELEASE_BIN are required")
endif()

file(GLOB ts_files RELATIVE "${TRANSLATIONS_SOURCE_DIR}" "${TRANSLATIONS_SOURCE_DIR}/*.ts")
list(FILTER ts_files EXCLUDE REGEX "^\\.")
list(SORT ts_files)

file(MAKE_DIRECTORY "${TRANSLATIONS_OUTPUT_DIR}")
file(GLOB stale_qm "${TRANSLATIONS_OUTPUT_DIR}/mmc_*.qm")
file(REMOVE ${stale_qm})

set(index_languages "")
set(qrc_files "        <file>index_v2.json</file>\n")
set(first_language TRUE)

foreach(ts_file IN LISTS ts_files)
    string(REGEX REPLACE "\\.ts$" "" lang "${ts_file}")

    # the Portuguese source declares itself as pt_PT
    if(lang STREQUAL "pt")
        set(lang "pt_PT")
    endif()

    set(qm_name "mmc_${lang}.qm")
    set(qm_path "${TRANSLATIONS_OUTPUT_DIR}/${qm_name}")

    execute_process(
        COMMAND "${LRELEASE_BIN}" "${TRANSLATIONS_SOURCE_DIR}/${ts_file}" -qm "${qm_path}"
        RESULT_VARIABLE lrelease_result
        OUTPUT_VARIABLE lrelease_output
        ERROR_VARIABLE lrelease_output
    )
    if(NOT lrelease_result EQUAL 0)
        message(FATAL_ERROR "lrelease failed for ${ts_file}:\n${lrelease_output}")
    endif()

    if(NOT lrelease_output MATCHES "\\(([0-9]+) finished and ([0-9]+) unfinished\\)")
        message(FATAL_ERROR "could not read the statistics lrelease reported for ${ts_file}:\n${lrelease_output}")
    endif()
    set(translated "${CMAKE_MATCH_1}")
    set(fuzzy "${CMAKE_MATCH_2}")

    # entries without any text are dropped from the .qm, lrelease only mentions them when there are some
    set(untranslated 0)
    if(lrelease_output MATCHES "Ignored ([0-9]+) untranslated source text")
        set(untranslated "${CMAKE_MATCH_1}")
    endif()

    file(SHA1 "${qm_path}" qm_sha1)
    file(SIZE "${qm_path}" qm_size)

    if(first_language)
        set(first_language FALSE)
    else()
        string(APPEND index_languages ",\n")
    endif()
    string(APPEND index_languages
        "        \"${lang}\" : {\n"
        "            \"file\" : \"${qm_name}\",\n"
        "            \"sha1\" : \"${qm_sha1}\",\n"
        "            \"size\" : ${qm_size},\n"
        "            \"translated\" : ${translated},\n"
        "            \"fuzzy\" : ${fuzzy},\n"
        "            \"untranslated\" : ${untranslated}\n"
        "        }"
    )
    string(APPEND qrc_files "        <file>${qm_name}</file>\n")
endforeach()

list(LENGTH ts_files language_count)

file(WRITE "${TRANSLATIONS_OUTPUT_DIR}/index_v2.json"
    "{\n"
    "    \"file_type\" : \"MMC-TRANSLATION-INDEX\",\n"
    "    \"version\" : 2,\n"
    "    \"languages\" : {\n"
    "${index_languages}\n"
    "    }\n"
    "}\n"
)

file(WRITE "${TRANSLATIONS_OUTPUT_DIR}/translations.qrc"
    "<RCC>\n"
    "    <qresource prefix=\"/translations\">\n"
    "${qrc_files}"
    "    </qresource>\n"
    "</RCC>\n"
)

message(STATUS "Generated ${language_count} translations in ${TRANSLATIONS_OUTPUT_DIR}")
