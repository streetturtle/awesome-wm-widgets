---
---

var hash = window.location.hash;

document.addEventListener('DOMContentLoaded', function() {
    var elems = document.querySelectorAll('.sidenav');
    var options = {};
    var instances = M.Sidenav.init(elems, options);

    if (hash)
        $('a[href=' + hash +']').click();
    else
        $('a[href=#tabMain]').click();
});

$(document).ready(function(){
    $('.sidenav').sidenav();
    $('.collapsible').collapsible();

    let currentPage = document.location.hash.replace('#tab', '').replace(/[\s+_]/g, '-').toLowerCase();
    if (currentPage === 'main') currentPage = 'awesome-wm-widgets';
    ga('set', 'page', currentPage);
    ga('send', 'pageview');

    $('li.tab > a').click(function(event){
        event.preventDefault();//stop browser to take action for clicked anchor

        let currentPage = $(this).text().trim().replace(/\s+/g, '-').toLowerCase();
        ga('set', 'page', currentPage);
        ga('send', 'pageview');

        //find actived navigation and remove 'active' css
        let actived_nav = $('li.active');
        actived_nav.removeClass('active');

        //add 'active' css into clicked navigation
        $(this).parents('li').addClass('active');

        //hide displaying tab content
        $('.widget.active').each(function(){$(this).removeClass('active fade-in').addClass('hide')})

        //show target tab content
        let target_tab_selector = $(this).attr('href');
        $(target_tab_selector).removeClass('hide');
        $(target_tab_selector).addClass('active fade-in');
    });
});

particlesJS.load('particles-js', 'assets/js/particlesjs-config.json', function() {
    console.log('callback - particles.js config loaded');
});

if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register("assets/js/service-worker.js").catch(function(e) {
        console.log("Error registering service worker" + e);
    });
}

