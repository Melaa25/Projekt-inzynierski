/*
   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
var showControllersOnly = false;
var seriesFilter = "";
var filtersOnlySampleSeries = true;

/*
 * Add header in statistics table to group metrics by category
 * format
 *
 */
function summaryTableHeader(header) {
    var newRow = header.insertRow(-1);
    newRow.className = "tablesorter-no-sort";
    var cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 1;
    cell.innerHTML = "Requests";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 3;
    cell.innerHTML = "Executions";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 7;
    cell.innerHTML = "Response Times (ms)";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 1;
    cell.innerHTML = "Throughput";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 2;
    cell.innerHTML = "Network (KB/sec)";
    newRow.appendChild(cell);
}

/*
 * Populates the table identified by id parameter with the specified data and
 * format
 *
 */
function createTable(table, info, formatter, defaultSorts, seriesIndex, headerCreator) {
    var tableRef = table[0];

    // Create header and populate it with data.titles array
    var header = tableRef.createTHead();

    // Call callback is available
    if(headerCreator) {
        headerCreator(header);
    }

    var newRow = header.insertRow(-1);
    for (var index = 0; index < info.titles.length; index++) {
        var cell = document.createElement('th');
        cell.innerHTML = info.titles[index];
        newRow.appendChild(cell);
    }

    var tBody;

    // Create overall body if defined
    if(info.overall){
        tBody = document.createElement('tbody');
        tBody.className = "tablesorter-no-sort";
        tableRef.appendChild(tBody);
        var newRow = tBody.insertRow(-1);
        var data = info.overall.data;
        for(var index=0;index < data.length; index++){
            var cell = newRow.insertCell(-1);
            cell.innerHTML = formatter ? formatter(index, data[index]): data[index];
        }
    }

    // Create regular body
    tBody = document.createElement('tbody');
    tableRef.appendChild(tBody);

    var regexp;
    if(seriesFilter) {
        regexp = new RegExp(seriesFilter, 'i');
    }
    // Populate body with data.items array
    for(var index=0; index < info.items.length; index++){
        var item = info.items[index];
        if((!regexp || filtersOnlySampleSeries && !info.supportsControllersDiscrimination || regexp.test(item.data[seriesIndex]))
                &&
                (!showControllersOnly || !info.supportsControllersDiscrimination || item.isController)){
            if(item.data.length > 0) {
                var newRow = tBody.insertRow(-1);
                for(var col=0; col < item.data.length; col++){
                    var cell = newRow.insertCell(-1);
                    cell.innerHTML = formatter ? formatter(col, item.data[col]) : item.data[col];
                }
            }
        }
    }

    // Add support of columns sort
    table.tablesorter({sortList : defaultSorts});
}

$(document).ready(function() {

    // Customize table sorter default options
    $.extend( $.tablesorter.defaults, {
        theme: 'blue',
        cssInfoBlock: "tablesorter-no-sort",
        widthFixed: true,
        widgets: ['zebra']
    });

    var data = {"OkPercent": 100.0, "KoPercent": 0.0};
    var dataset = [
        {
            "label" : "FAIL",
            "data" : data.KoPercent,
            "color" : "#FF6347"
        },
        {
            "label" : "PASS",
            "data" : data.OkPercent,
            "color" : "#9ACD32"
        }];
    $.plot($("#flot-requests-summary"), dataset, {
        series : {
            pie : {
                show : true,
                radius : 1,
                label : {
                    show : true,
                    radius : 3 / 4,
                    formatter : function(label, series) {
                        return '<div style="font-size:8pt;text-align:center;padding:2px;color:white;">'
                            + label
                            + '<br/>'
                            + Math.round10(series.percent, -2)
                            + '%</div>';
                    },
                    background : {
                        opacity : 0.5,
                        color : '#000'
                    }
                }
            }
        },
        legend : {
            show : true
        }
    });

    // Creates APDEX table
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.1368421052631579, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.125, 500, 1500, "06 Raport stanu magazynowego (CSV)"], "isController": false}, {"data": [0.12745098039215685, 500, 1500, "04 Przyjecie materialu do partii"], "isController": false}, {"data": [0.11538461538461539, 500, 1500, "03 Szczegoly partii (skan etykiety)"], "isController": false}, {"data": [0.11, 500, 1500, "05 Wydanie materialu z partii"], "isController": false}, {"data": [0.07142857142857142, 500, 1500, "07 Raport historii ruchow (CSV)"], "isController": false}, {"data": [0.5, 500, 1500, "00 Pobranie partii do testu"], "isController": false}, {"data": [0.288135593220339, 500, 1500, "01 Sprawdzenie polaczenia (ping)"], "isController": false}, {"data": [0.03571428571428571, 500, 1500, "02 Lista partii"], "isController": false}, {"data": [0.0, 500, 1500, "00 Logowanie"], "isController": false}]}, function(index, item){
        switch(index){
            case 0:
                item = item.toFixed(3);
                break;
            case 1:
            case 2:
                item = formatDuration(item);
                break;
        }
        return item;
    }, [[0, 0]], 3);

    // Create statistics table
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 285, 0, 0.0, 2813.6666666666665, 55, 7100, 2647.0, 4656.6, 5255.599999999999, 6986.779999999998, 2.2190904065217896, 164.88605901466545, 0.756356708563353], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["06 Raport stanu magazynowego (CSV)", 8, 0, 0.0, 2096.75, 1297, 3900, 1687.0, 3900.0, 3900.0, 3900.0, 0.07266583706502684, 1.8987852883471246, 0.020508229406047615], "isController": false}, {"data": ["04 Przyjecie materialu do partii", 51, 0, 0.0, 2843.372549019608, 97, 5774, 2756.0, 4826.000000000001, 5219.0, 5774.0, 0.4578836795891616, 0.745402435424934, 0.2301780836445745], "isController": false}, {"data": ["03 Szczegoly partii (skan etykiety)", 52, 0, 0.0, 2838.634615384615, 303, 6055, 2863.5, 4447.3, 5153.049999999993, 6055.0, 0.44629063819561265, 5.586989193007827, 0.12682673409660475], "isController": false}, {"data": ["05 Wydanie materialu z partii", 50, 0, 0.0, 2614.0199999999995, 578, 6969, 2474.0, 4601.5, 4945.549999999999, 6969.0, 0.45578435930392613, 0.7397593800421145, 0.18516239596722], "isController": false}, {"data": ["07 Raport historii ruchow (CSV)", 7, 0, 0.0, 3326.285714285714, 1203, 4594, 3594.0, 4594.0, 4594.0, 4594.0, 0.07195649715771837, 3.3712542467182693, 0.02058911490938621], "isController": false}, {"data": ["00 Pobranie partii do testu", 1, 0, 0.0, 1174.0, 1174, 1174, 1174.0, 1174.0, 1174.0, 1174.0, 0.8517887563884157, 295.82107777896084, 0.23540646294718912], "isController": false}, {"data": ["01 Sprawdzenie polaczenia (ping)", 59, 0, 0.0, 2355.9830508474574, 55, 7100, 2237.0, 4578.0, 5846.0, 7100.0, 0.4874623042921469, 0.23421040401536747, 0.13329047382988393], "isController": false}, {"data": ["02 Lista partii", 56, 0, 0.0, 3504.5357142857147, 1211, 7096, 3438.5, 5360.9000000000015, 6123.4, 7096.0, 0.4652708541043536, 161.5820750638709, 0.12858559737454303], "isController": false}, {"data": ["00 Logowanie", 1, 0, 0.0, 2084.0, 2084, 2084, 2084.0, 2084.0, 2084.0, 2084.0, 0.4798464491362764, 0.3209910328694818, 0.12745921305182342], "isController": false}]}, function(index, item){
        switch(index){
            // Errors pct
            case 3:
                item = item.toFixed(2) + '%';
                break;
            // Mean
            case 4:
            // Mean
            case 7:
            // Median
            case 8:
            // Percentile 1
            case 9:
            // Percentile 2
            case 10:
            // Percentile 3
            case 11:
            // Throughput
            case 12:
            // Kbytes/s
            case 13:
            // Sent Kbytes/s
                item = item.toFixed(2);
                break;
        }
        return item;
    }, [[0, 0]], 0, summaryTableHeader);

    // Create error table
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": []}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 285, 0, "", "", "", "", "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
