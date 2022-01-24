mkdir ./_widgets
for D in *; do
    if [[ -d "${D}" ]] && [[ ${D} == *"-widget"* ]]; then
        echo "${D}"
        cp ${D}/README.md ./_widgets/${D}.md
        sed -i '1s/^/---\nlayout: page\n---\n/' ./_widgets/${D}.md

        mkdir -p ./assets/img/widgets/screenshots/${D}

        find ${D}/ \( -name '*.jpg' -o -name '*.png' -o -name '*.gif' \) -exec cp '{}' ./assets/img/widgets/screenshots/${D} \;

        sed -i "s/](\.\(\/screenshots\)\{0,1\}/](..\/awesome-wm-widgets\/assets\/img\/widgets\/screenshots\/$D/g" ./_widgets/${D}.md
    fi
done
