document.addEventListener('DOMContentLoaded', function() {
    var elems = document.querySelectorAll('.sidenav');
    var options = {};
    var instances = M.Sidenav.init(elems, options);
});

// Initialize collapsible (uncomment the lines below if you use the dropdown variation)
// var collapsibleElem = document.querySelector('.collapsible');
// var collapsibleInstance = M.Collapsible.init(collapsibleElem, options);

// Or with jQuery

$(document).ready(function(){
    $('.sidenav').sidenav();

    $('.sidenav > li > a').click(function(event){

        event.preventDefault();//stop browser to take action for clicked anchor

        //get displaying tab content jQuery selector
        var active_tab_selector = $('.sidenav > li.active > a').attr('href');

        //find actived navigation and remove 'active' css
        var actived_nav = $('.sidenav > li.active');
        actived_nav.removeClass('active');

        //add 'active' css into clicked navigation
        $(this).parents('li').addClass('active');

        //hide displaying tab content
        $(active_tab_selector).removeClass('active fade-in');
        $(active_tab_selector).addClass('hide ');

        //show target tab content
        var target_tab_selector = $(this).attr('href');
        $(target_tab_selector).removeClass('hide');
        $(target_tab_selector).addClass('active fade-in');
    });

    var hash = window.location.hash;
    $('tab'+hash+':first').addClass('active');

});

particlesJS.load('particles-js', 'assets/js/particlesjs-config.json', function() {
    console.log('callback - particles.js config loaded');
});
