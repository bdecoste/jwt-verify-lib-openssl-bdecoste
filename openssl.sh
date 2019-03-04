set -x 

SOURCE_DIR=$1
TARGET=$2

if [ "${GIT_RESET}" == "true" ]; then
  pushd ${SOURCE_DIR}
    git fetch upstream
    git checkout master
    git reset --hard upstream/master
  popd
fi

if [ "$TARGET" == "RESET" ]; then
  exit
fi

if [ "$TARGET" == "BORINGSSL" ]; then
  exit
fi

/usr/bin/cp -rf src/* ${SOURCE_DIR}/src/
/usr/bin/cp -rf jwt_verify_lib/* ${SOURCE_DIR}/jwt_verify_lib/

cp openssl.BUILD ${SOURCE_DIR}

function replace_text() {
  START=$(grep -nr "${DELETE_START_PATTERN}" ${SOURCE_DIR}/${FILE} | cut -d':' -f1)
  START=$((${START} + ${START_OFFSET}))
  if [[ ! -z "${DELETE_STOP_PATTERN}" ]]; then
    STOP=$(tail --lines=+${START}  ${SOURCE_DIR}/${FILE} | grep -nr "${DELETE_STOP_PATTERN}" - |  cut -d':' -f1 | head -1)
    CUT=$((${START} + ${STOP} - 1))
  else
    CUT=$((${START}))
  fi

  if [ "${START}" != "0" ]; then 
    CUT_TEXT=$(sed -n "${START},${CUT} p" ${SOURCE_DIR}/${FILE})
    sed -i "${START},${CUT} d" ${SOURCE_DIR}/${FILE}

    if [[ ! -z "${ADD_TEXT}" ]]; then
      ex -s -c "${START}i|${ADD_TEXT}" -c x ${SOURCE_DIR}/${FILE}
    fi
  fi
}

FILE="repositories.bzl"
DELETE_START_PATTERN="actual = \"@boringssl//:ssl\","
DELETE_STOP_PATTERN=")"
START_OFFSET="-3"
ADD_TEXT=""
replace_text

FILE="repositories.bzl"
DELETE_START_PATTERN="def boringssl_repositories(bind = True):"
DELETE_STOP_PATTERN="),"
START_OFFSET="0"
ADD_TEXT="def bsslwrapper_repositories(bind = True):
    http_archive(
        name = \"bssl_wrapper\",
        strip_prefix = \"bssl_wrapper-34df33add45e1a02927fcf79b0bdd5899b7e2e36\",
        url = \"https://github.com/bdecoste/bssl_wrapper/archive/34df33add45e1a02927fcf79b0bdd5899b7e2e36.tar.gz\",
        sha256 = \"d9e500e1a8849c81e690966422baf66016a7ff85d044c210ad85644f62827158\",
    )

    if bind:
        native.bind(
            name = \"bssl_wrapper_lib\",
            actual = \"@bssl_wrapper//:bssl_wrapper_lib\",
        )
        
def opensslcbs_repositories(bind = True):
    http_archive(
        name = \"openssl_cbs\",
        strip_prefix = \"openssl-cbs-563fe95a2d5690934f903d9ebb3d9bbae40fc93f\",
        url = \"https://github.com/bdecoste/openssl-cbs/archive/563fe95a2d5690934f903d9ebb3d9bbae40fc93f.tar.gz\",
        sha256 = \"44453d398994a8d8fa540b2ffb5bbbb0a414c030236197e224ee6298adb53bdb\",
    )

    if bind:
        native.bind(
            name = \"openssl_cbs_lib\",
            actual = \"@openssl_cbs//:openssl_cbs_lib\",
        )
"
replace_text

FILE="repositories.bzl"
DELETE_START_PATTERN="BORINGSSL_COMMIT ="
DELETE_STOP_PATTERN="BORINGSSL_SHA256 ="
START_OFFSET="0"
ADD_TEXT=""
replace_text

FILE="repositories.bzl"
DELETE_START_PATTERN="name = \"boringssl\","
DELETE_STOP_PATTERN=")"
START_OFFSET="-1"
ADD_TEXT=""
replace_text

FILE="BUILD"
DELETE_START_PATTERN="\"//external:protobuf\","
DELETE_STOP_PATTERN="\"//external:ssl\","
START_OFFSET="0"
ADD_TEXT="        \"//external:protobuf\",
        \"//external:bssl_wrapper_lib\",
        \"//external:openssl_cbs_lib\",
        \"@openssl//:openssl-lib\","
replace_text

FILE="WORKSPACE"
DELETE_START_PATTERN="\"boringssl_repositories\","
DELETE_STOP_PATTERN=""
START_OFFSET="0"
ADD_TEXT="    \"bsslwrapper_repositories\",
    \"opensslcbs_repositories\","
replace_text

FILE="WORKSPACE"
DELETE_START_PATTERN="boringssl_repositories()"
DELETE_STOP_PATTERN=""
START_OFFSET="0"
ADD_TEXT="bsslwrapper_repositories()
opensslcbs_repositories()"
replace_text

OPENSSL_REPO="
new_local_repository(
    name = \"openssl\",
    path = \"/usr/lib64/\",
    build_file = \"openssl.BUILD\"
)"
echo "${OPENSSL_REPO}" >> ${SOURCE_DIR}/WORKSPACE







