function bindEvents() {
    $('.sidebar-users').on('click', 'input[type=checkbox]', function() {
        var num = $(this).closest('div').find('input[type=checkbox]').index($(this));
        $('.stat-report tbody tr:eq(' + num + ')').fadeToggle();
    });
}

function buildUi() {
    //buildTabs();
}

function buildTabs() {
    $('ul.unico-tabs__caption').on('click', 'li:not(.active)', function() {
        $(this)
            .addClass('active').siblings().removeClass('active')
            .closest('div.unico-tabs').find('div.unico-tabs__content')
            .removeClass('active').eq($(this).index()).addClass('active');
    });
}

$(document).ready(function() {
    buildUi();
    bindEvents();
});
