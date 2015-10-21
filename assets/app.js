$.ajaxSetup({ cache: true });
var jisilu_base_est_val = {};
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
            if (dataF && dataF.length) {
                jingzhi_gusuan = parseFloat(dataF[2]) * (1 + zs_zhangfu / 100); // 0.95 仓位
                hebing_yijia = Math.floor(10000 * (hb_price - jingzhi_gusuan) / hb_price) / 100;

                jingzhi_gusuan = Math.floor(10000 * jingzhi_gusuan) / 10000;

                // （母基金净值/B份额价格）* 初始杠杆
                jiage_ganggan = Math.floor( 1000 * (dataF[2] / dataB[3]) * 2 ) / 1000; // A:B = 5:5

                // (母基金净值/B份额净值)×初始杠杆
                jingzhi_ganggan = Math.floor( 1000 * (dataF[2] / netB[2]) * 2 ) / 1000; // A:B = 5:5
            }

            tbody += '<tr><td>' + displayCode(row[0]) + '</td>';
            // tbody += '<td>' + dataA[0] + '</td>';
            tbody += '<td>' + dataA[3] + '</td><td>' + displayPct(Math.floor(10000 * (dataA[3] - dataA[2]) / dataA[2]) / 100) + '</td>';

            tbody += '<td>' + displayCode(row[1]) + '</td><td>' + dataB[0] + '</td><td>' + dataB[3] + '</td><td>' + displayPct(Math.floor(10000 * (dataB[3] - dataB[2]) / dataB[2]) / 100) + '</td>';

            tbody += '<td>' + hb_price + '</td><td>' + jingzhi_gusuan + '</td><td>' + displayPct(hebing_yijia) + '</td>';

            if (row[3] in jisilu_base_est_val) {
                tbody += '<td>' + jisilu_base_est_val[row[3]][0] + '</td><td>' + displayPct(jisilu_base_est_val[row[3]][1]) + '</td>';
            } else {
                tbody += '<td>-</td><td>-</td>';
            }

        // 不太准
        if (0) {
            var gs1 = getFundGS1Value(row[3]);
            if (! isNaN(gs1)) {
                var yijia = Math.floor(10000 * (hb_price - gs1) / hb_price) / 100;
                tbody += '<td><a href="http://fund.fund123.cn/html/' + row[3] + '/index.html" target="_blank">' + gs1 + '</a></td><td>' + displayPct(yijia) + '</td>';
            } else {
                tbody += '<td>-</td><td>-</td>';
            }
        }

            // <td>' + (dataF ? displayName(dataF[1]) : '') + '</td>
            tbody += '<td>' + row[3] + '</td><td>' + (dataF ? dataF[2] : '') + '</td>';

            tbody += '<td>' + displayCode(row[2]) + '</td><td>' + dataM[0] + '</td><td>' + displayPct(zs_zhangfu) + '</td>';

            tbody += '<td>' + jiage_ganggan + '</td><td>' + jingzhi_ganggan + '</td><td>' + Math.floor(dataA[9] / 10000) + '</td><td>' + Math.floor(dataB[9] / 10000) + '</td>';

            tbody += '<td>' + netB[2] + '</td>'

            tbody += '</tr>';
        });

        $('#table_data > tbody').html(tbody);
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

function setFundGS1value(code) {
    var url = "http://hqqd.fund123.cn/HQ_EV_" + code + '.js';
    $.getScript(url, function() {
        fdata = eval("HQ_EV_" + code);
        if (parseFloat(fdata[5]) > 0) {
            localStorage.setItem('g1_' + code, fdata[5]);
        }
    });
}

function getFundGS1Value(code) {
    return localStorage.getItem('g1_' + code);
}

function setFundGS2value(code) {
    $.getJSON('data/jisilu.json', function(data) {
        $.each(data.rows, function(i, v) {
            jisilu_base_est_val[v.cell.base_fund_id] = [v.cell.base_est_val, v.cell.est_dis_rt];
        });
    });
}

function getFundNetValue(code) {
    var fdata = localStorage.getItem('m_' + code);
    if (fdata) fdata = JSON.parse(fdata);
    var require_fetch = 0;
    if (! fdata) require_fetch = 1;
    if (fdata && $.now() - fdata[fdata.length-1] > 3600 * 1000) require_fetch = 1;
    if (require_fetch) {
        var url = "http://hqqd.fund123.cn/HQ_NV_" + code + '.js';
        $.getScript(url, function() {
            fdata = eval("HQ_NV_" + code);
            if ( parseFloat(fdata[2]) > 0 ) {
                fdata.push( $.now() );
                localStorage.setItem('m_' + code, JSON.stringify(fdata));
            }
        });
        return [];
    }
    return fdata;
}

$(document).ready(function() {
    render();

    var hour = (new Date()).getHours();
    if (hour >= 9 && hour <= 15) {
        console.log(hour);
        window.setInterval(render, 5000);
        $.each(symbol_list, function(i, row) {
            var code = row[3];
            window.setInterval(function() {
                setFundGS1value(code);
            }, 10000); // every 10 seconds
        });
    } else {
        $.each(symbol_list, function(i, row) {
            var code = row[3];
            setFundGS1value(code);
        });
    }

    setFundGS2value();
    window.setInterval(function() {
        setFundGS2value();
    }, 10000);

    $.extend( true, $.fn.dataTable.defaults, {
        "searching": false,
        "paging": false,
        "info": false
    } );

    $('#table_data').DataTable();

    $('#index_change').load('data/index_change.html', function() {
        $('#table_index_change').DataTable();
    });
});