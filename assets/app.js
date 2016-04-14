$.ajaxSetup({ cache: true });
var fund_netvalue = {};
var jisilu_data = {};
function render() {
    var xxx = $.map(symbol_list, function(n){ return n; }); // flatten
    xxx = $.grep(xxx, function(n) {
        return (n.indexOf('sz') > -1 || n.indexOf('sh') > -1);
    });
    xxx = $.unique(xxx);
    var url = "http://hq.sinajs.cn/list=" + xxx.join(',');
    $.getScript( url, function() {
        var tbody = '';
        $.each(symbol_list, function(i, row) {
            var xA = eval("hq_str_" + row[0]);
            var xB = eval("hq_str_" + row[1]);
            var xM = eval("hq_str_" + row[2]);
            var dataA = xA.split(',');
            var dataB = xB.split(',');
            var dataM = xM.split(',');
            var dataF = getFundNetValue(row[3]);

            var cleanB = row[1].replace('sz', '');
            var netB  = getFundNetValue(cleanB);

            // 合并价格
            var hb_price = Math.floor(10000 * ( parseFloat(dataA[3]) + parseFloat(dataB[3]) ) / 2) / 10000;
            var zs_zhangfu = Math.floor(10000 * (dataM[3] - dataM[2]) / dataM[2]) / 100; // 指数涨幅

            var jingzhi_gusuan = '-'; // 净值估算
            var hebing_yijia = '-';   // 合并溢价
            var jiage_ganggan = '-'; // 价格杠杆
            var jingzhi_ganggan = '-'; // 净值杠杆
            if (dataF) {
                jingzhi_gusuan = parseFloat(dataF) * (1 + zs_zhangfu / 100); // 0.95 仓位
                hebing_yijia = Math.floor(10000 * (hb_price - jingzhi_gusuan) / hb_price) / 100;

                jingzhi_gusuan = Math.floor(10000 * jingzhi_gusuan) / 10000;

                // （母基金净值/B份额价格）* 初始杠杆
                jiage_ganggan = Math.floor( 1000 * (dataF / dataB[3]) * 2 ) / 1000; // A:B = 5:5

                // (母基金净值/B份额净值)×初始杠杆
                jingzhi_ganggan = Math.floor( 1000 * (dataF / netB) * 2 ) / 1000; // A:B = 5:5
            }

            tbody += '<tr>';

            // tbody += '<td>' + displayCode(row[0]) + '</td>';
            // tbody += '<td>' + dataA[0] + '</td>';
            tbody += '<td>' + dataA[3] + '</td><td>' + displayPct(Math.floor(10000 * (dataA[3] - dataA[2]) / dataA[2]) / 100) + '</td>';

            tbody += '<td>' + displayCode(row[1]) + '</td><td>' + dataB[0] + '</td><td>' + dataB[3] + '</td><td>' + displayPct(Math.floor(10000 * (dataB[3] - dataB[2]) / dataB[2]) / 100) + '</td>';

            tbody += '<td>' + hb_price + '</td><td>' + jingzhi_gusuan + '</td><td>' + displayPct(hebing_yijia) + '</td>';

            if (row[3] in jisilu_data) {
                tbody += '<td>' + jisilu_data[row[3]].base_est_val + '</td><td>' + displayPct(jisilu_data[row[3]].est_dis_rt) + '</td>';
            } else {
                tbody += '<td>-</td><td>-</td>';
            }

            tbody += '<td>' + row[3] + '</td><td>' + dataF + '</td>';

            // tbody += '<td>' + displayCode(row[2]) + '</td>';

            tbody += '<td><span data-toggle="tooltip" data-placement="right" title="' + displayCode(row[2]) + '" onclick="javascript: FundStock(\'' + row[1] + '\')">' + dataM[0] + '</span></td><td>' + displayPct(zs_zhangfu) + '</td>';

            tbody += '<td>' + jiage_ganggan + '</td><td>' + jingzhi_ganggan + '</td><td>' + Math.floor(dataA[9] / 10000) + '</td><td>' + Math.floor(dataB[9] / 10000) + '</td>';

            tbody += '<td>' + netB + '</td>'

            tbody += '</tr>';
        });

        $('#table_data > tbody').html(tbody);
        $('[data-toggle="tooltip"]').tooltip();
    });
}

function displayCode(code) {
    if (! code) return '-';
    return code.replace('sz', '').replace('sh', '');
}
function displayPct(pct) {
    if (pct == '-') return '-';
    pct = parseFloat(pct.toString().replace('%', ''));
    if (pct > 0) {
        return '<span style="color:red">' + pct + '%</span>';
    } else if (pct < 0) {
        return '<span style="color:green">' + pct + '%</span>';
    } else {
        return pct + '%';
    }
}
function displayName(name) {
    return name.replace('指数分级', '')
}

function setFundGS2value(code) {
    $.getJSON('data/jisilu.json', function(data) {
        $.each(data.rows, function(i, v) {
            jisilu_data[v.id] = v.cell;
        });
    });
}

function setFundNetValue() {
    $.getJSON('data/fund_value.json', function(data) {
        fund_netvalue = data;
    });
}

function getFundNetValue(code) {
    if (code in fund_netvalue) {
        return fund_netvalue[code];
    }
    return;
}

function FundStock(b_id) {
    var xxx = [];
    $('#fund_stock_' + b_id).find('[data-id]').each(function(){
        xxx.push($(this).attr('data-id'));
    });
    xxx = $.grep(xxx, function(n) {
        return (n.indexOf('sz') > -1 || n.indexOf('sh') > -1);
    });
    xxx = $.unique(xxx);
    var url = "http://hq.sinajs.cn/list=" + xxx.join(',');
    $.getScript( url, function() {
        $.each(xxx, function(i, v) {
            var x = eval("hq_str_" + v);
            var d = x.split(',');
            if (parseFloat(d[1]) == 0) {
                $('[data-id="' + v + '"]').text('-');
            } else {
                $('[data-id="' + v + '"]').html(
                    displayPct(Math.floor(10000 * (d[3] - d[2]) / d[2]) / 100)
                );
            }
        });
        $('#fund_stock_' + b_id).modal('show');
    });
}

$(document).ready(function() {
    render();

    var hour = (new Date()).getHours();
    if (hour >= 9 && hour <= 15) {
        console.log(hour);
        window.setInterval(render, 5000);
    }

    setFundGS2value();
    setFundNetValue(); // 母基金单位净值
    window.setInterval(function() {
        setFundGS2value();
    }, 10000);

    $('#index_history_data').load('data/index_history_data.html', function() {
        $('#table_index_history_data').DataTable({
            "searching": false,
            "paging": false,
            "info": false
        });
    });
    $('#jsl_data').load('data/jisilu.html', function() {
        $('#table_jsl_data').DataTable({
            "searching": false,
            "paging": false,
            "info": false
        });
        $('[data-toggle="tooltip"]').tooltip();
    });
    $('#longhubang_data').load('data/longhubang.html', function() {
        $('#table_longhubang_data').DataTable({
            "searching": false,
            "paging": false,
            "info": false
        });
    });
    $('#high_data').load('data/stock_high_data.html', function() {
        $('#table_high_data').DataTable({
            "searching": false,
            "paging": false,
            "info": false
        });
    });

    // for modal
    $.ajax({
        url: "data/fund_stock.html",
        success: function (data) { $('body').append(data); },
        dataType: 'html'
    });
});