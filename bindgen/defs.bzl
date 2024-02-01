load("//bindgen/private:rust_bindgen_tools.bzl", _bindgen_tool_files = "bindgen_tool_files")
load("//bindgen/private:rust_bindgen_tools.bzl", _prebuilt_bindgen_register_toolchains = "prebuilt_bindgen_register_toolchains")

bindgen_tool_files = _bindgen_tool_files
prebuilt_bindgen_register_toolchains = _prebuilt_bindgen_register_toolchains
