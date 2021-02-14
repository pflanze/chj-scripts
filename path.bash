# Add this directory to PATH if not there already.

function PATH_add {
    local dir="$1"
    case ":$PATH:" in
        *:"$dir":*) ;;
        *) PATH=$dir:$PATH;
    esac
}

PATH_add /opt/chj/bin
