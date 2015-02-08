$(function(){
    //メモリアイコンの描画をヒモ付
    $.jqplot.postDrawHooks.push(function() {
        //$.fn.drawTickIcon()
        $(".xaxis").show();
        $(".yaxis").show();
    });

    //最初は隠しておこう
    $(".xaxis").hide();
    $(".yaxis").hide();

    //チェックボックス箇所の横線を設定(43はcssで定義してあるチェックアイコンのサイズ）
    var width = $(".checkbox").height() - 43;
    $(".uncheckedline").css("width", width);
    $(".checkedline").css("width", width);


    $(document).on("ajax:beforeSend", function(){ 
        var msg = "検索しています・・・";
        var crits = $("#crit-result").val();
        if (crits.search(/icongeo/) != -1) {
            msg += "30秒ほどかかるかもしれません・・・";
        }
        else if (crits.search(/simapps/) != -1) {
            msg += "30秒ほどかかるかもしれません・・・";
        }
        else {
            msg += "10秒ほどで終わるはずです・・・";
        }
        msg += "<i class='fa fa-spin fa-spinner'></i>";            
        $(".status").html(msg);});

    //チェックボックス風トグルボタン達
    var buttons = $("#input-app .checkbox .btn");
    var upClasses = ["pull-left", "unchecked"];
    var downClasses = ["pull-right", "checked"];

    //submit時にトグルボタンたちの状態をまとめて送信
    $("#input-app .btn[type=submit]").on("click", function() {
        var res = "";
        for (i = 0; i < buttons.length; i++) {
            state = $(buttons[i]).attr("state");
            if (state == "down") {
                res += $(buttons[i]).attr("name") + ","
            }
        }
        //まとめた状態で上書き
        $("#crit-result").val(res);    
    });

    //チェックボックス風トグルボタン達にクリックイベントを紐付け
    for (i = 0; i < buttons.length; i++) {
        $(buttons[i]).on("click", function() {
            var parent = $(this).parent().get(0);
            var height = $(parent).height();
            //チェックされていない状態でクリックされた時
            if ($(this).attr("state") == "up") {
                $(this).attr("state", "down");
                for (j = 0; j < upClasses.length; j++) {
                    $(this).removeClass(upClasses[j]);
                    $(this).addClass(downClasses[j]);
                }
            }
            //チェックされた状態でクリックされた時
            else {                
                $(this).attr("state", "up");
                for (j = 0; j < upClasses.length; j++) {
                    $(this).removeClass(downClasses[j]);
                    $(this).addClass(upClasses[j]);
                }
            }
            //pull-(left||right)をすると親の高さが0になってしまう・・・とりあえず応急処置
            $(parent).height(height);
        });
    }
    //わかりやすさのために基準ボタンを一つクリックしておく
    $("#input-app .btn[name=title]").click();      
});


