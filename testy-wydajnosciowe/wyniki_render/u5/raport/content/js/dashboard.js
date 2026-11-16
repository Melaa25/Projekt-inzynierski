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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.5549019607843138, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.6, 500, 1500, "06 Raport stanu magazynowego (CSV)"], "isController": false}, {"data": [0.6222222222222222, 500, 1500, "04 Przyjecie materialu do partii"], "isController": false}, {"data": [0.6702127659574468, 500, 1500, "03 Szczegoly partii (skan etykiety)"], "isController": false}, {"data": [0.5888888888888889, 500, 1500, "05 Wydanie materialu z partii"], "isController": false}, {"data": [0.3888888888888889, 500, 1500, "07 Raport historii ruchow (CSV)"], "isController": false}, {"data": [0.5, 500, 1500, "00 Pobranie partii do testu"], "isController": false}, {"data": [0.6530612244897959, 500, 1500, "01 Sprawdzenie polaczenia (ping)"], "isController": false}, {"data": [0.28125, 500, 1500, "02 Lista partii"], "isController": false}, {"data": [0.0, 500, 1500, "00 Logowanie"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 255, 0, 0.0, 1000.1254901960784, 49, 3267, 1028.0, 2036.0000000000005, 2249.1999999999994, 2975.6, 2.0459742447948006, 146.79826029506157, 0.6969256478918442], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["06 Raport stanu magazynowego (CSV)", 10, 0, 0.0, 971.6999999999999, 313, 2998, 555.0, 2876.9000000000005, 2998.0, 2998.0, 0.08873114463176575, 2.3248339757098493, 0.025042285936113576], "isController": false}, {"data": ["04 Przyjecie materialu do partii", 45, 0, 0.0, 786.5777777777777, 94, 2241, 663.0, 1659.0, 2150.799999999999, 2241.0, 0.41125185063332786, 0.6694890966853101, 0.20672366788671384], "isController": false}, {"data": ["03 Szczegoly partii (skan etykiety)", 47, 0, 0.0, 766.340425531915, 89, 2282, 664.0, 1616.2000000000005, 2100.2, 2282.0, 0.4102975967036517, 4.41011945552636, 0.11659824281324475], "isController": false}, {"data": ["05 Wydanie materialu z partii", 45, 0, 0.0, 956.0222222222225, 119, 2746, 935.0, 2074.0, 2202.2, 2746.0, 0.40921367319286694, 0.664172973482954, 0.1662430547346022], "isController": false}, {"data": ["07 Raport historii ruchow (CSV)", 9, 0, 0.0, 1439.2222222222222, 498, 2288, 1496.0, 2288.0, 2288.0, 2288.0, 0.0903532813300003, 3.4305815425814936, 0.025853038505556727], "isController": false}, {"data": ["00 Pobranie partii do testu", 1, 0, 0.0, 1427.0, 1427, 1427, 1427.0, 1427.0, 1427.0, 1427.0, 0.7007708479327259, 243.37826296426067, 0.19367006832515768], "isController": false}, {"data": ["01 Sprawdzenie polaczenia (ping)", 49, 0, 0.0, 716.1632653061224, 49, 2663, 639.0, 1508.0, 1900.0, 2663.0, 0.4151909030825806, 0.19948625421545865, 0.11352876256164314], "isController": false}, {"data": ["02 Lista partii", 48, 0, 0.0, 1650.0624999999998, 1053, 3267, 1477.0, 2462.5, 2874.7499999999995, 3267.0, 0.4129884879458985, 143.4230322953771, 0.11413646688348562], "isController": false}, {"data": ["00 Logowanie", 1, 0, 0.0, 2205.0, 2205, 2205, 2205.0, 2205.0, 2205.0, 2205.0, 0.45351473922902497, 0.30337655895691606, 0.12046485260770974], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 255, 0, "", "", "", "", "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
