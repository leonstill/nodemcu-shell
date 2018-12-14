(function(){
   function success(text) {
      var data0 = JSON.parse(text).wifiscan
      var data = []
      for (var k in data0) {
         var ary = data0[k].split(',')
         data.push({
            mac: k,
            ssid: ary[0],
            rssi: ary[1],
            bssid: ary[2],
            channel: ary[3],
         })
      }
      document.getElementById("content").innerHTML = tmpl("tmpl-demo", { title: "Wifi状态", items: data });
   }

   function fail(code) {
      // var textarea = document.getElementById('test-response-text');
      // textarea.value = 'Error code: ' + code;
   }

   var request = new XMLHttpRequest(); // 新建XMLHttpRequest对象
   request.onreadystatechange = function () { // 状态发生变化时，函数被回调
      if (request.readyState === 4) { // 成功完成
         // 判断响应结果:
         if (request.status === 200) {
            // 成功，通过responseText拿到响应的文本:
            return success(request.responseText);
         } else {
            // 失败，根据响应码判断失败原因:
            return fail(request.status);
         }
      } else {
         // HTTP请求还在继续...
      }
   }
   setInterval(function () {
      // 发送请求:
      request.open('GET', '/api.lua?req=wifiscan');
      request.send();
   }, 5000)
})();
