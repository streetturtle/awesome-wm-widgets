---
---

$(document).ready(function(){
    $('.sidenav').sidenav();
    $('.collapsible').collapsible({
        accordion: false // Allow multiple sections to be open
    });

    let collapsibleTimeout = null;

    function showTab(targetHash) {
        //hide displaying tab content
        $('.widget.active').each(function(){$(this).removeClass('active fade-in').addClass('hide')})

        //show target tab content
        let targetElement = $(targetHash);
        targetElement.removeClass('hide');
        targetElement.addClass('active fade-in');

        //find actived navigation and remove 'active' css
        let actived_nav = $('li.active');
        actived_nav.removeClass('active');

        //add 'active' css into clicked navigation
        let targetLink = $('a[href="' + targetHash + '"]');
        targetLink.parents('li').addClass('active');

        // Clear any pending collapsible operations
        if (collapsibleTimeout) {
            clearTimeout(collapsibleTimeout);
        }

        // Open the collapsible section containing the target link
        collapsibleTimeout = setTimeout(function() {
            let collapsibleBody = targetLink.closest('.collapsible-body');
            if (collapsibleBody.length > 0) {
                // Get the li that contains the collapsible-header (parent of collapsible-body)
                let collapsibleItem = collapsibleBody.parent('li');
                let collapsibleParent = collapsibleItem.parent('.collapsible');
                
                if (collapsibleParent.length > 0 && collapsibleItem.length > 0) {
                    // Get the actual index among ALL children (including non-collapsible items)
                    let allChildren = collapsibleParent.children('li');
                    let index = allChildren.index(collapsibleItem);
                    
                    if (index >= 0) {
                        let collapsibleInstance = M.Collapsible.getInstance(collapsibleParent[0]);
                        if (collapsibleInstance) {
                            collapsibleInstance.open(index);
                        }
                    }
                }
            }
            collapsibleTimeout = null;
        }, 50);

        let currentPage = targetHash.replace('#tab', '').replace(/[\s+_]/g, '-').toLowerCase();
        if (currentPage === 'main') currentPage = 'awesome-wm-widgets';
        ga('set', 'page', currentPage);
        ga('send', 'pageview');
    }

    // Handle all navigation link clicks
    $('a.tab[href^="#tab"]').on('click', function(event){
        event.preventDefault();
        event.stopPropagation(); // Prevent collapsible from closing
        event.stopImmediatePropagation(); // Stop all other handlers

        let target_tab_selector = $(this).attr('href');
        
        // Update URL hash - this will trigger the hashchange event
        window.location.hash = target_tab_selector;
        
        return false; // Extra safety to prevent default behavior
    });

    // Handle browser back/forward buttons
    $(window).on('hashchange', function() {
        let hash = window.location.hash || '#tabMain';
        showTab(hash);
    });

    // Show initial tab based on URL hash
    let initialHash = window.location.hash || '#tabMain';
    showTab(initialHash);
});

particlesJS.load('particles-js', 'assets/js/particlesjs-config.json', function() {
    console.log('callback - particles.js config loaded');
});

if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register("assets/js/service-worker.js").catch(function(e) {
        console.log("Error registering service worker" + e);
    });
}

