#!/bin/bash
set -euo pipefail

IMAGE=threema/webrtc-build-tools:latest
BUILD_ARGS="${WEBRTC_BUILD_ARGS:-symbol_level=1 debuggable_apks=false enable_libaom=false rtc_enable_protobuf=false rtc_include_dav1d_in_internal_decoder_factory=false use_siso=false android_static_analysis=\\\"off\\\" is_component_build=false rtc_include_tests=false use_goma=false}"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <revision>"
    echo "Example: $0 branch-heads/4430"
    exit 1
fi
revision=$1

rm -rf ./out && mkdir -p ./out
docker run --platform linux/amd64 --rm -v "$(pwd)/out:/out" \
    $IMAGE /bin/bash -c "
    set -euo pipefail

    export OUT='/out'

    echo '==> Fetching sources'
    fetch --nohooks webrtc_android

    echo '==> Change current working directory to src/ of the workspace'
    cd src

    echo '==> Checking out revision $revision'
    git checkout $revision

    echo '==> Run gclient sync'
    gclient sync

    echo '==> Log revision and build args'
    git log --pretty=fuller HEAD...HEAD^ > \$OUT/revision.txt
    echo \"BUILD_ARGS: $BUILD_ARGS\" >> \$OUT/build_args.txt

    echo '==> Build directly with GN and Ninja'
    source build/android/envsetup.sh

    # Define Android architectures
    DEFAULT_ARCHS=(armeabi-v7a arm64-v8a x86 x86_64)

    # Build for each Android architecture
    for arch in \"\${DEFAULT_ARCHS[@]}\"; do
        echo \"Building for \$arch\"
        
        # Convert arch names
        case \$arch in
            armeabi-v7a) gn_arch=\"arm\" ;;
            arm64-v8a) gn_arch=\"arm64\" ;;
            x86) gn_arch=\"x86\" ;;
            x86_64) gn_arch=\"x64\" ;;
        esac
        
        # Generate build files
        gn gen out/\$arch --args=\"target_os=\\\"android\\\" target_cpu=\\\"\$gn_arch\\\" $BUILD_ARGS\"
        
        # Build the required targets
        ninja -C out/\$arch sdk/android:libwebrtc sdk/android:libjingle_peerconnection_so
    done

    echo '==> Create AAR manually'
    python3 tools_webrtc/android/build_aar.py --build-dir out --output \$OUT/libwebrtc.aar

    echo 'Done!'
"
