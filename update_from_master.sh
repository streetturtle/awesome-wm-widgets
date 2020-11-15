#!/usr/bin/env bash

master_dir="$HOME/.config/awesome/awesome-wm-widgets/"
pages_dir="$HOME/home-dev/awesome-wm-widgets/"
cd ${master_dir}

for D in *; do
    if [[ -d "${D}" ]] && [[ ${D} == *"-widget"* ]]; then
        echo "${D}"
        cp ${D}/README.md ${pages_dir}/_widgets/${D}.md
        sed -i '1s/^/---\nlayout: page\n---\n/' ${pages_dir}/_widgets/${D}.md

        mkdir -p ${pages_dir}/assets/img/screenshots/${D}

        find ${D}/ \( -name '*.jpg' -o -name '*.png' -o -name '*.gif' \) -exec cp '{}' ${pages_dir}/assets/img/screenshots/${D} \;

        sed -i "s/](\.\(\/screenshots\)\{0,1\}/](..\/awesome-wm-widgets\/assets\/img\/screenshots\/$D/g" ${pages_dir}/_widgets/${D}.md
    fi
done
