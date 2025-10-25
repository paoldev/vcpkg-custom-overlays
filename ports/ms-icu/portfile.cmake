# "ms-icu" port partially based on "vcpkg/ports/opengl/portfile.cmake" and "vcpkg/ports/winsock2/portfile.cmake"
#
# Note: use "dummyheaders" feature to try to compile "standard" icu dependent packages without applying any modification. However,
#       U_ICU_VERSION macro and c++ code are not exposed by "ms-icu", so compile-time errors may still happen.
#       In this case, this port has to be used together with custom icu port, that declares its own "ms-icu" feature.
#       Usage example:
#           vcpkg install --triplet x64-windows my_icu_dependent_package icu[ms-icu]
#

vcpkg_get_windows_sdk(WINDOWS_SDK)

set(HEADERSPATH "$ENV{WindowsSdkDir}Include\\${WINDOWS_SDK}\\um")
set(LIBSPATH "$ENV{WindowsSdkDir}Lib\\${WINDOWS_SDK}\\um\\${TRIPLET_SYSTEM_ARCH}")

list(APPEND icu_headers "icu.h")
list(APPEND icu_lib "icu.lib")
list(APPEND legacy_headers "icui18n.h;icucommon.h")
list(APPEND legacy_libs "icuin.Lib;icuuc.lib")

function(find_icu_files header_list lib_list result_found)
  set(${result_found} OFF PARENT_SCOPE)
  foreach(header ${header_list})
    if (NOT EXISTS "${HEADERSPATH}\\${header}")
	  return()
	endif()
  endforeach()
  foreach(lib ${lib_list})
    if (NOT EXISTS "${LIBSPATH}\\${lib}")
	  return()
	endif()
  endforeach()
  set(${result_found} ON PARENT_SCOPE)
endfunction()

if (WINDOWS_SDK MATCHES "10.")
  find_icu_files("${icu_headers}" "${icu_lib}" ICU_FOUND)
  find_icu_files("${legacy_headers}" "${legacy_libs}" LEGACY_ICU_FOUND)
endif()

if (ICU_FOUND AND NOT "forcelegacy" IN_LIST FEATURES)
  message(STATUS "ICU found in Windows SDK version ${WINDOWS_SDK}.")
  set(ICU_DUMMY_FILE_CONTENT "#pragma once\n\n#include <icu.h>\n")
  set(ICU_LIBS ${icu_lib})
elseif (LEGACY_ICU_FOUND)
  message(STATUS "Legacy ICU found in Windows SDK version ${WINDOWS_SDK}.")
  set(ICU_DUMMY_FILE_CONTENT "#pragma once\n\n//icui18n.h already includes icucommon.h\n#include <icui18n.h>\n")
  set(ICU_LIBS ${legacy_libs})
else()
  message(FATAL_ERROR "ICU not found in Windows SDK version ${WINDOWS_SDK}.")
endif()

if("dummyheaders" IN_LIST FEATURES)
  list(APPEND dummyheaders alphaindex.h appendable.h basictz.h brkiter.h bytestream.h bytestrie.h bytestriebuilder.h calendar.h caniter.h casemap.h char16ptr.h chariter.h choicfmt.h coleitr.h coll.h compactdecimalformat.h curramt.h currpinf.h currunit.h datefmt.h dbbi.h dcfmtsym.h decimfmt.h displayoptions.h docmain.h dtfmtsym.h dtintrv.h dtitvfmt.h dtitvinf.h dtptngen.h dtrule.h edits.h enumset.h errorcode.h fieldpos.h filteredbrk.h fmtable.h format.h formattedvalue.h fpositer.h gender.h gregocal.h icudataver.h icuplug.h idna.h listformatter.h localebuilder.h localematcher.h localpointer.h locdspnm.h locid.h measfmt.h measunit.h measure.h messagepattern.h msgfmt.h normalizer2.h normlzr.h nounit.h numberformatter.h numberrangeformatter.h numfmt.h numsys.h parseerr.h parsepos.h platform.h plurfmt.h plurrule.h ptypes.h putil.h rbbi.h rbnf.h rbtz.h regex.h region.h reldatefmt.h rep.h resbund.h schriter.h scientificnumberformatter.h search.h selfmt.h simpleformatter.h simpletz.h smpdtfmt.h sortkey.h std_string.h strenum.h stringoptions.h stringpiece.h stringtriebuilder.h stsearch.h symtable.h tblcoll.h timezone.h tmunit.h tmutamt.h tmutfmt.h translit.h tzfmt.h tznames.h tzrule.h tztrans.h ubidi.h ubiditransform.h ubrk.h ucal.h ucasemap.h ucat.h uchar.h ucharstrie.h ucharstriebuilder.h uchriter.h uclean.h ucnv.h ucnvsel.h ucnv_cb.h ucnv_err.h ucol.h ucoleitr.h uconfig.h ucpmap.h ucptrie.h ucsdet.h ucurr.h udat.h udata.h udateintervalformat.h udatpg.h udisplaycontext.h udisplayoptions.h uenum.h ufieldpositer.h uformattable.h uformattedvalue.h ugender.h uidna.h uiter.h uldnames.h ulistformatter.h uloc.h ulocdata.h umachine.h umisc.h umsg.h umutablecptrie.h unifilt.h unifunct.h unimatch.h unirepl.h uniset.h unistr.h unorm.h unorm2.h unum.h unumberformatter.h unumberrangeformatter.h unumsys.h uobject.h upluralrules.h uregex.h uregion.h ureldatefmt.h urename.h urep.h ures.h uscript.h usearch.h uset.h usetiter.h ushape.h uspoof.h usprep.h ustdio.h ustream.h ustring.h ustringtrie.h utext.h utf.h utf16.h utf32.h utf8.h utf_old.h utmscale.h utrace.h utrans.h utypes.h uvernum.h uversion.h vtzone.h)
  foreach (header IN LISTS dummyheaders)
    file(WRITE "${CURRENT_PACKAGES_DIR}/include/unicode/${header}" ${ICU_DUMMY_FILE_CONTENT})
  endforeach()
else()
    # Allow empty include directory
	set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
endif()

#PkgConfig and vcpkg-cmake-wrapper.cmake: for simplicity, use the same .pc file to export all libs
set(PC_ICU_LIBS "")
set(WRAPPER_ICU_LIBS "")
set(WRAPPER_ICU_IN_LIBS "")
file(TO_CMAKE_PATH "${LIBSPATH}" WRAPPER_ICU_LIBS_PATH)
foreach (lib ${ICU_LIBS})
  string(TOLOWER ${lib} lib)
  string(REPLACE ".lib" "" lib ${lib})
  set(PC_ICU_LIBS ${PC_ICU_LIBS} " -l${lib}")
  if ("${lib}" STREQUAL "icuin")
    set(WRAPPER_ICU_IN_LIBS ${WRAPPER_ICU_IN_LIBS} " ${lib}")
  else()
    set(WRAPPER_ICU_LIBS ${WRAPPER_ICU_LIBS} " ${lib}")
  endif()
endforeach()
if("${WRAPPER_ICU_IN_LIBS}" STREQUAL "")
  set(WRAPPER_ICU_IN_LIBS ${WRAPPER_ICU_LIBS})
endif()
string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)" WINDOWS_SDK_SEMVER "${WINDOWS_SDK}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/icu.pc.in" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-i18n.pc" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/icu.pc.in" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-io.pc" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/icu.pc.in" "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-uc.pc" @ONLY)
if(NOT VCPKG_BUILD_TYPE)
  file(COPY "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-i18n.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
  file(COPY "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-io.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
  file(COPY "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/icu-uc.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
endif()
vcpkg_fixup_pkgconfig()
configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" "${CURRENT_PACKAGES_DIR}/share/icu/vcpkg-cmake-wrapper.cmake" @ONLY)
#PkgConfig and vcpkg-cmake-wrapper.cmake: End

#copyright
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright" "See https://developer.microsoft.com/windows/downloads/windows-10-sdk for the Windows 10 SDK license")
#file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
