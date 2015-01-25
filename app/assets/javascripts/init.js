$(function(){
    $("#inputapp")
        .on("ajax:beforeSend", function(){ $("#msg").html("検索中・・・"); }) ;

    //チェックボックス風トグルボタン達
    var buttons = $("#char-togglebuttons").children();
    var left = "pull-left";
    var right = "pull-right";

    //submit時にトグルボタンたちの状態をまとめて送信
    $("#submit_btn")
        .on("click", function() {

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
            val = $(this).attr("state");
            //チェックされていない状態でクリックされた時
            if (val == "up") {
                $(this).attr("state", "down");
                $(this).removeClass(left);
                $(this).addClass(right);
            }
            //チェックされた状態でクリックされた時
            else {                
                $(this).attr("state", "up");
                $(this).removeClass(right);
                $(this).addClass(left);
            }
        });
    }
});


