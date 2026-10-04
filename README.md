> **Filmio fork (`filmio` branch).** Upstream 2.1.0 plus a Mac Catalyst slice
> (`ios-arm64_x86_64-maccatalyst`, `aarch64` / `x86_64-apple-ios-macabi`, stable Rust).
> `./build-catalyst.sh` builds just that slice and merges it into the existing `Dovi.xcframework`.
> Tags: `2.1.0-filmio.N`.

# LibDovi

[libdovi](https://github.com/quietvoid/dovi_tool) (the C API of the `dolby_vision` Rust crate, the reference Dolby Vision RPU library behind `dovi_tool`) cross-compiled for Apple platforms and packaged as a SwiftPM binary target.

Used by [AetherEngine](https://github.com/superuser404notfound/AetherEngine) to convert Dolby Vision Profile 7 RPUs to single-layer Profile 8.1 live (`dovi_convert_rpu_with_mode(rpu, 2)`), so the player engages real Dolby Vision on dual-layer UHD-BD remuxes instead of plain HDR10.

## Consuming

```swift
.package(url: "https://github.com/superuser404notfound/LibDovi", from: "2.1.0"),
// then add the product:
.product(name: "Dovi", package: "LibDovi"),
```

`import Dovi` exposes the libdovi C API (`dovi_parse_unspec62_nalu`, `dovi_convert_rpu_with_mode`, `dovi_write_unspec62_nalu`, the free functions, etc.).

## Slices

`Dovi.xcframework` ships seven slices:

- `macos-arm64_x86_64` (fat: Apple Silicon + Intel Macs)
- `ios-arm64` (device)
- `ios-arm64_x86_64-simulator` (fat: Apple Silicon + Intel Macs)
- `tvos-arm64` (device)
- `tvos-arm64-simulator` (Apple Silicon only)
- `xros-arm64` (device)
- `xros-arm64-simulator` (Apple Silicon only)

Minimum deployment tvOS 17.0 / iOS 16.0 / visionOS 1.0. The tvOS and visionOS simulators stay arm64-only: there is no Intel Vision Pro, and `x86_64-apple-tvos` is a low-tier Rust target with no prebuilt std (would need nightly + `-Z build-std`) whose Intel-Mac tvOS-simulator use is not worth that cost. Everything is built with stable Rust.

## Rebuilding

`./build.sh` cross-compiles libdovi (`dolby_vision` 3.4.0, `capi` feature) via `cargo-c` for each slice and assembles the XCFramework. Requires Rust stable (the tvOS and visionOS targets are tier-2 with prebuilt std) and `cargo-c`:

```sh
rustup target add aarch64-apple-tvos aarch64-apple-tvos-sim \
    aarch64-apple-ios aarch64-apple-ios-sim \
    aarch64-apple-visionos aarch64-apple-visionos-sim \
    x86_64-apple-ios x86_64-apple-darwin
cargo install cargo-c
./build.sh
```

The prebuilt `Dovi.xcframework` is committed (mirroring FFmpegBuild), so consumers do not need a Rust toolchain.

## License

libdovi is dual-licensed MIT / Apache-2.0 (see the upstream dovi_tool repository) and is consumed here under the MIT option. The packaging in this repo (build script, SwiftPM stubs) is MIT, see [LICENSE](LICENSE). No additional restrictions.
