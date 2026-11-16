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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.813953488372093, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.7727272727272727, 500, 1500, "06 Raport stanu magazynowego (CSV)"], "isController": false}, {"data": [1.0, 500, 1500, "04 Przyjecie materialu do partii"], "isController": false}, {"data": [0.9230769230769231, 500, 1500, "03 Szczegoly partii (skan etykiety)"], "isController": false}, {"data": [1.0, 500, 1500, "05 Wydanie materialu z partii"], "isController": false}, {"data": [0.65, 500, 1500, "07 Raport historii ruchow (CSV)"], "isController": false}, {"data": [0.5, 500, 1500, "00 Pobranie partii do testu"], "isController": false}, {"data": [1.0, 500, 1500, "01 Sprawdzenie polaczenia (ping)"], "isController": false}, {"data": [0.4230769230769231, 500, 1500, "02 Lista partii"], "isController": false}, {"data": [0.0, 500, 1500, "00 Logowanie"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 86, 0, 0.0, 480.89534883720927, 50, 2178, 224.0, 1308.2, 1495.35, 2178.0, 0.6933303235272777, 45.553157991135855, 0.22778244140955667], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["06 Raport stanu magazynowego (CSV)", 11, 0, 0.0, 563.6363636363636, 305, 1304, 482.0, 1223.6000000000004, 1304.0, 1304.0, 0.09700005290911977, 2.5381393460873705, 0.027375991494858996], "isController": false}, {"data": ["04 Przyjecie materialu do partii", 12, 0, 0.0, 178.08333333333334, 111, 327, 163.0, 311.70000000000005, 327.0, 327.0, 0.11517309556487604, 0.1874937014713363, 0.057867732097781954], "isController": false}, {"data": ["03 Szczegoly partii (skan etykiety)", 13, 0, 0.0, 221.6153846153846, 117, 632, 161.0, 595.5999999999999, 632.0, 632.0, 0.11476191316937093, 1.1229460100372535, 0.03261300462137396], "isController": false}, {"data": ["05 Wydanie materialu z partii", 12, 0, 0.0, 177.75, 102, 238, 170.5, 234.70000000000002, 238.0, 238.0, 0.11516093741003051, 0.18691159958542064, 0.0467841308228249], "isController": false}, {"data": ["07 Raport historii ruchow (CSV)", 10, 0, 0.0, 711.8000000000001, 481, 1502, 506.5, 1500.1, 1502.0, 1502.0, 0.09853381680592779, 3.2250387668985496, 0.028193758129039886], "isController": false}, {"data": ["00 Pobranie partii do testu", 1, 0, 0.0, 1162.0, 1162, 1162, 1162.0, 1162.0, 1162.0, 1162.0, 0.8605851979345955, 298.88359240533566, 0.237837510757315], "isController": false}, {"data": ["01 Sprawdzenie polaczenia (ping)", 13, 0, 0.0, 61.307692307692314, 50, 158, 52.0, 119.99999999999997, 158.0, 158.0, 0.11430782217220033, 0.05492133643429938, 0.03125604512521103], "isController": false}, {"data": ["02 Lista partii", 13, 0, 0.0, 1288.5384615384614, 1111, 1536, 1250.0, 1523.6, 1536.0, 1536.0, 0.11332136194843005, 39.355644112083546, 0.031318306085357135], "isController": false}, {"data": ["00 Logowanie", 1, 0, 0.0, 2178.0, 2178, 2178, 2178.0, 2178.0, 2178.0, 2178.0, 0.4591368227731864, 0.3071374253902663, 0.12195821854912764], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 86, 0, "", "", "", "", "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
