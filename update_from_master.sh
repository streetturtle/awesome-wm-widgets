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
        cp ${D}/*.{png,gif,jpg,svg} ${pages_dir}/assets/img/screenshots/${D}

        sed -i "s/](./](..\/awesome-wm-widgets\/assets\/img\/screenshots\/$D/g" ${pages_dir}/_widgets/${D}.md
    fi
done
