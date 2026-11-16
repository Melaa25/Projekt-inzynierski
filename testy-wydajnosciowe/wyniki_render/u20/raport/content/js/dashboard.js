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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.015151515151515152, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.0, 500, 1500, "06 Raport stanu magazynowego (CSV)"], "isController": false}, {"data": [0.0, 500, 1500, "04 Przyjecie materialu do partii"], "isController": false}, {"data": [0.0, 500, 1500, "03 Szczegoly partii (skan etykiety)"], "isController": false}, {"data": [0.0, 500, 1500, "05 Wydanie materialu z partii"], "isController": false}, {"data": [0.0, 500, 1500, "07 Raport historii ruchow (CSV)"], "isController": false}, {"data": [0.5, 500, 1500, "00 Pobranie partii do testu"], "isController": false}, {"data": [0.056451612903225805, 500, 1500, "01 Sprawdzenie polaczenia (ping)"], "isController": false}, {"data": [0.00819672131147541, 500, 1500, "02 Lista partii"], "isController": false}, {"data": [0.0, 500, 1500, "00 Logowanie"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 297, 0, 0.0, 6575.895622895626, 99, 15131, 5725.0, 12209.2, 12869.499999999996, 15036.38, 2.3268385550097537, 177.85233584819923, 0.7921386936799304], "isController": false}, "titles": ["Label", "#Samples", "FAIL", "Error %", "Average", "Min", "Max", "Median", "90th pct", "95th pct", "99th pct", "Transactions/s", "Received", "Sent"], "items": [{"data": ["06 Raport stanu magazynowego (CSV)", 5, 0, 0.0, 7179.8, 3003, 11013, 6997.0, 11013.0, 11013.0, 11013.0, 0.04471711950203016, 1.168767509547105, 0.012620358921959684], "isController": false}, {"data": ["04 Przyjecie materialu do partii", 55, 0, 0.0, 6021.545454545455, 1824, 15131, 4679.0, 11538.0, 13009.8, 15131.0, 0.48556546305288245, 0.7904664325284718, 0.2441018280436126], "isController": false}, {"data": ["03 Szczegoly partii (skan etykiety)", 60, 0, 0.0, 8398.599999999999, 2323, 15036, 8305.5, 12761.3, 13189.25, 15036.0, 0.5266484095218031, 5.401746333210449, 0.1496627804402781], "isController": false}, {"data": ["05 Wydanie materialu z partii", 48, 0, 0.0, 4528.666666666667, 1513, 13085, 3652.5, 9671.900000000001, 12228.25, 13085.0, 0.4646840148698885, 0.754203938197026, 0.1887778810408922], "isController": false}, {"data": ["07 Raport historii ruchow (CSV)", 4, 0, 0.0, 8974.5, 4806, 12191, 9450.5, 12191.0, 12191.0, 12191.0, 0.04556068113218293, 2.569284270174839, 0.013036405831767184], "isController": false}, {"data": ["00 Pobranie partii do testu", 1, 0, 0.0, 1166.0, 1166, 1166, 1166.0, 1166.0, 1166.0, 1166.0, 0.8576329331046312, 297.81973627787306, 0.2370216016295026], "isController": false}, {"data": ["01 Sprawdzenie polaczenia (ping)", 62, 0, 0.0, 4876.806451612904, 99, 10968, 4646.5, 8233.9, 9157.849999999999, 10968.0, 0.5188588452880085, 0.24929546082197285, 0.14187546550843982], "isController": false}, {"data": ["02 Lista partii", 61, 0, 0.0, 8574.901639344262, 1328, 15055, 8707.0, 12929.0, 13751.3, 15055.0, 0.5101016858442601, 177.151013160728, 0.14097536825578671], "isController": false}, {"data": ["00 Logowanie", 1, 0, 0.0, 2170.0, 2170, 2170, 2170.0, 2170.0, 2170.0, 2170.0, 0.4608294930875576, 0.3082697292626728, 0.12240783410138249], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 297, 0, "", "", "", "", "", "", "", "", "", ""], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
