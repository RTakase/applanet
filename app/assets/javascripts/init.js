$(function(){
    //メモリアイコンの描画をヒモ付
    $.jqplot.postDrawHooks.push(function() {$.fn.drawTickIcon() });

    $(document).on("ajax:beforeSend", function(){ 
        var msg = "検索しています・・・";
        var chars = $("#char-result").val();
        if (chars.search(/icongeo/) != -1) {
            //msg += "30～60秒ほどかかるかもしれません・・・";
            msg += "10秒ほどで終わるはずです・・・";
        }
        else {
            msg += "10秒ほどで終わるはずです・・・";
        }
        msg += "<i class='fa fa-spin fa-spinner'></i>";            
        $(".msg").html(msg);});

    //チェックボックス風トグルボタン達
    var buttons = $("#input-app .chars .btn");
    var upClasses = ["pull-left", "btn-primary"];
    var downClasses = ["pull-right", "btn-success"];

    //submit時にトグルボタンたちの状態をまとめて送信
    $("#input-app .form-inline .btn").on("click", function() {
        var res = "";
        for (i = 0; i < buttons.length; i++) {
            state = $(buttons[i]).attr("state");
            if (state == "down") {
                res += $(buttons[i]).attr("name") + ","
            }
        }
        //まとめた状態で上書き
        $("#char-result").val(res);    
    });

    //チェックボックス風トグルボタン達にクリックイベントを紐付け
    for (i = 0; i < buttons.length; i++) {
        $(buttons[i]).on("click", function() {
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
        });
    }
    //わかりやすさのために基準ボタンを一つクリックしておく
    $("#input-app .btn[name=title]").click();      
});


