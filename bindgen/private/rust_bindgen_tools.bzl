
load("@rules_cc//cc:defs.bzl", "CcInfo")
load("@rules_rust//rust/private:utils.bzl", "get_preferred_artifact")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain", "use_cpp_toolchain")

def _get_libs_for_static_executable(dep):
    linker_inputs = dep[CcInfo].linking_context.linker_inputs.to_list()
    print(linker_inputs)
    return depset([get_preferred_artifact(lib, use_pic = False) for li in linker_inputs for lib in li.libraries])


def _bindgen_tool_files_impl(ctx):
    print(ctx.files.bindgen)
    print(ctx.files.clang)
    print(ctx.files.libclang)

    files = []
    files.extend(ctx.files.bindgen)
    files.extend(ctx.files.clang)

    libclang = _get_libs_for_static_executable(ctx.attr.libclang).to_list()[0]
    files.append(libclang)

    print(libclang)
    return [
        DefaultInfo(files = depset(files))
    ]

bindgen_tool_files = rule(
    implementation = _bindgen_tool_files_impl,
    attrs = {
        "bindgen": attr.label(
            doc = "The label of a `bindgen` executable.",
            executable = True,
            cfg = "exec",
        ),
        "clang": attr.label(
            doc = "The label of a `clang` executable.",
            executable = True,
            cfg = "exec",
            allow_files = True,
        ),
        "libclang": attr.label(
            doc = "A cc_library that provides bindgen's runtime dependency on libclang.",
            cfg = "exec",
            providers = [CcInfo],
            allow_files = True,
        ),
    },
)


def _cc_library_from_file_impl(ctx):
    cc_toolchain = ctx.attr._cc_toolchain

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    library_to_link = cc_common.create_library_to_link(
        actions = ctx.actions,
        dynamic_library = ctx.file.lib,
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
    )

    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        libraries = depset([library_to_link])
    )

    linking_context = cc_common.create_linking_context(
        linker_inputs = depset([linker_input])
    )

    cc_info = CcInfo(linking_context = linking_context)
    return [
        cc_info,
    ]


cc_library_from_file_x = rule(
    implementation = _cc_library_from_file_impl,
    attrs = {
        "lib": attr.label(
            doc = "A cc_library that provides bindgen's runtime dependency on libclang.",
            cfg = "exec",
            allow_single_file = True,
        ),
        "_cc_toolchain": attr.label(
            default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")
        ),
    },
    fragments = ["cpp"],
)

def prebuilt_bindgen_register_toolchains(url, sha256):
    build_file = """# Biuld file for bindgen_prebuilt_binaries

filegroup(
  name = "prebuilt_bindgen",
  srcs = [ "bindgen-cli" ],
  visibility = ["//visibility:public"],
)

filegroup(
  name = "prebuilt_clang",
  srcs = [ "clang" ],
  visibility = ["//visibility:public"],
)

filegroup(
  name = "prebuilt_libclang",
  srcs = [ "libclang.so" ],
  visibility = ["//visibility:public"],
)
"""

    http_archive(
        name = "bindgen_prebuilt_tools",
        url = url,
        sha256 = sha256,
        build_file_content = build_file,
    )

    native.register_toolchains("//bindgen:prebuilt_bindgen_toolchain")
