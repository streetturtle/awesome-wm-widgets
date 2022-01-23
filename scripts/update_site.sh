for D in *; do
    if [[ -d "${D}" ]] && [[ ${D} == *"-widget"* ]]; then
        echo "${D}"
        cp ${D}/README.md ./_widgets/${D}.md
        sed -i '1s/^/---\nlayout: page\n---\n/' ./_widgets/${D}.md
    fi
done