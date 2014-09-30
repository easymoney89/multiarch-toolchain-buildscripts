###### DO NOT EDIT THIS FILE ######

# ============== GENERIC BUILD STEPS =================

# Prepare directories (create if necessary)
mkdir -p "${BUILDDIR}" "${PACKDIR}"

# Wget the packages if necessary
cd "${PACKDIR}"
for k in ${!PACKS[@]}; do
    if [ ! -e "${PACKS[$k]}" ]; then
        wget "${SITES[$k]}/${PACKS[$k]}" || { echo "Error downloading ${PACKS[$k]}"; exit 1; }
    fi
done

# Unpack if necessary
cd "${BUILDDIR}"
for p in "${PACKS[@]}"; do
    [ ! -d "${p%%.tar.*}" ] && { tar -xaf "${PACKDIR}/${p}" || { echo "Error unpacking ${p}"; exit 2; } }
done

# Make build directories
for p in "${PACKS[@]}"; do mkdir -p "build-${p%%.tar.*}"; done

# Set-up some environment variables useful during the build process
export LD_LIBRARY_PATH="${PREFIX}/lib"
export PATH="${PREFIX}/bin:${PATH}"

# configure, make and make install all packs
GCC_BOOTSTRAPPED=0
for t in "${OPTS[@]}"; do
    cd "build-${PACKS[$t]%%.tar.*}"

    if [ "${t}" = 'GCC' -a "${GCC_BOOTSTRAPPED}" = 1 ]; then  # GCC again (post-bootstrap)
        "../${PACKS[$t]%%.tar.*}/configure" --prefix="${PREFIX}" ${GCC2}
    else  [ ! -e Makefile ] && "../${PACKS[$t]%%.tar.*}/configure" --prefix="${PREFIX}" ${!t};  fi
    [ $? != 0 ] && { echo "Error configuring ${PACKS[$t]}"; exit 3; }

    if [ ${t} = 'GCC' ]; then make -j${THR} all-gcc all-target-libgcc; else make -j${THR} all; fi
    [ $? != 0 ] && { echo "Error making ${PACKS[$t]}"; exit 4; }

    if [ ${t} = 'GCC' ]; then make install-gcc install-target-libgcc; else make install; fi
    [ $? != 0 ] && { echo "Error installing ${PACKS[$t]}"; exit 5; }
    [ ${t} = 'GCC' ] && GCC_BOOTSTRAPPED=1

    cd ..
done

# Cleanup build directories
cd "${BUILDDIR}"
for p in "${PACKS[@]}"; do rm -rf "build-${p%%.tar.*}" "${p%%.tar.*}"; done
cd ..
rm -rf "${BUILDDIR}"