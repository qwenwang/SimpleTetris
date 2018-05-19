import QtQuick 2.5
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1

Window {
    visible: true
    width: 340
    height: 500
    title: qsTr("Russian Blocks")

    Item {
        id: root
        anchors.fill: parent

        property var blocks: null
        property var currentBlocks: null
        property int xOffset;
        property int yOffset;
        property int score;
        property var blockTypes: [
            [0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0]
        ]

        Rectangle {
            id: mainRect
            anchors.left: root.left
            anchors.top: root.top
            anchors.bottom: root.bottom
            anchors.margins: 10
            width: 200
            border.width: 1
            border.color: "black"

            Repeater {
                id: repeater
                model: 10*24
                delegate: blockComponent
            }

            Component {
                id: blockComponent
                Rectangle {
                    x: index%10*20+1
                    y:Math.floor(index/10)*20+1
                    width: 18
                    height: 18
                    color: "white"
                }
            }
        }

        Rectangle {
            id: nextBlock
            anchors.top: parent.top
            anchors.left: mainRect.right
            anchors.right: parent.right
            anchors.margins: 10
            height: 120
            border.color: "black"
        }

        Rectangle {
            id: scoreBlock
            anchors.top: nextBlock.bottom
            anchors.left: mainRect.right
            anchors.right: parent.right
            anchors.margins: 10
            height: 50
            border.color: "black"

            Text {
                anchors.centerIn: parent
                text: root.score
                font.pixelSize: parent.height-10
                color: "black"
            }
        }

        Timer {
            interval: 200
            repeat: true
            running: true
            onTriggered: {
                if(root.currentBlocks === null || !root.moveDown()){
                    if(root.currentBlocks !== null){
                        root.eraseBlocks();
                    }
                    root.createNewBlocks();
                }
                root.refresh();
            }
        }

        focus: true

        Keys.onPressed: {
            if(event.key === Qt.Key_Left){
                root.moveLeft();
            }
            else if(event.key === Qt.Key_Right){
                root.moveRight();
            }
            else if(event.key === Qt.Key_Up){
                root.rotate();
            }
            else if(event.key === Qt.Key_Down){
                root.moveBottom();
            }
        }

        MultiPointTouchArea {
            anchors.fill: parent
            mouseEnabled: true
            minimumTouchPoints: 1
            maximumTouchPoints: 1
            property var tracer: []

            touchPoints: [
                TouchPoint {
                    id: point
                }
            ]

            onReleased: {
                if(Math.abs(point.startX-point.x) > Math.abs(point.startY-point.y)) {
                    if(point.x > point.startX) {
                        root.moveRight()
                    } else {
                        root.moveLeft()
                    }
                } else {
                    if(point.y > point.startY) {
                        root.moveBottom()
                    } else {
                        root.rotate()
                    }
                }
            }
        }



        Component.onCompleted: {
            blocks = new Array(24);
            for(var i = 0;i<24;i++){
                blocks[i] = new Array(10);
                for(var j = 0;j<10;j++){
                    blocks[i][j] = 0;
                }
            }
        }

        function createNewBlocks(){
            root.currentBlocks = root.blockTypes[Math.floor(Math.random()*root.blockTypes.length)];
            root.xOffset = 0;
            root.yOffset = 0;
        }

        function eraseBlocks(){
            var eraseCount = 0;
            for(var i = 23; i >= 0;i--){
                var complete = true;
                var empty = true;
                for(var j = 0;j<10;j++){
                    if(blocks[i][j] === 0){
                        complete = false;
                    } else {
                        empty = false;
                    }
                }
                if(complete){
                    eraseCount++;
                }
                else if(eraseCount > 0){
                    for(j = 0;j<10;j++){
                        blocks[i+eraseCount][j] = blocks[i][j];
                    }
                }
                if(empty === true){
                    break
                }
            }
            if(eraseCount > 0){
                score += eraseCount*2-1;
            }
        }

        function moveLeft(){
            if(root.currentBlocks == null){
                return false;
            }
            if(isOverlap(currentBlocks, -1, 0)){
                xOffset -= 1;
                refresh();
                return true;
            } else {
                return false;
            }
        }

        function moveRight(){
            if(root.currentBlocks == null){
                return false;
            }
            if(isOverlap(currentBlocks, 1, 0)){
                xOffset += 1;
                refresh();
                return true;
            } else {
                return false;
            }
        }

        function rotate(){
            var tempArray = new Array(16);
            for(var i = 0;i<16;i++){
                var x = i % 4;
                var y = Math.floor(i / 4);

                var newX = 4 - y - 1;
                var newY = x;

                var newPosition = newY * 4 + newX;
                tempArray[newPosition] = currentBlocks[i];
            }
            if(isOverlap(tempArray, 0, 0)){
                currentBlocks = tempArray;
                refresh();
                return true;
            } else {
                return false;
            }
        }

        function moveDown(){
            if(root.currentBlocks == null){
                return false;
            }
            if(isOverlap(currentBlocks, 0, 1)){
                yOffset += 1;
                return true;
            } else {
                for(var i = 0;i<16;i++){
                    if(root.currentBlocks[i] != null && root.currentBlocks[i] === 1){
                        root.blocks[Math.floor(i/4)+yOffset-2][i%4+xOffset+3] = 1
                    }
                }
            }
        }

        function moveBottom(){
            var distances = [-1, -1, -1, -1];
            var maxY = -1;
            for(var i = 0;i<16;i++){
                if(root.currentBlocks[i] != null && root.currentBlocks[i] === 1){
                    distances[i%4] = Math.floor(i/4);
                }
            }
            for(i = 0;i<4;i++){
                maxY = Math.max(maxY, distances[i]);
            }
            var distances2 = [24, 24, 24, 24];
            for(var i = 3+xOffset;i<8+xOffset;i++){
                for(var j = maxY+yOffset-1;j<24;j++){
                    if(blocks[j][i] === 1 && distances2[i-3-xOffset] === 24){
                        distances2[i-3-xOffset] = j;
                        break;
                    }
                }
            }
            var minDistance = 24
            for(i=0;i<4;i++){
                if(distances[i] === -1){
                    continue;
                }
                minDistance = Math.min(minDistance, distances2[i]-distances[i]-yOffset+1);
            }
            yOffset += minDistance;
            refresh();
        }

        function isOverlap(tempBlocks, px, py){
            if(tempBlocks == null){
                return false
            }
            var minRow = 3;
            var maxRow = 0;
            var minCol = 3;
            var maxCol = 0;
            for(var i = 0;i<16;i++){
                if(tempBlocks[i] === 1){
                    minRow = Math.min(minRow, Math.floor(i/4));
                    maxRow = Math.max(maxRow, Math.floor(i/4));
                    minCol = Math.min(minCol, i%4);
                    maxCol = Math.max(maxCol, i%4);
                }
            }

            if(root.yOffset+py+2 > 24+3-maxRow){
                return false
            }
            if(root.xOffset+px-2 < -5-minCol || root.xOffset+px+2 > 5+3-maxCol){
                return false
            }
            for(var i = 0;i<16;i++){
                if(tempBlocks[i] === 1
                        && root.blocks[Math.floor(i/4)+yOffset+py-2] != null
                        && root.blocks[Math.floor(i/4)+yOffset+py-2][i%4+xOffset+px+3] != null
                        && root.blocks[Math.floor(i/4)+yOffset+py-2][i%4+xOffset+px+3] === 1){
                    return false;
                }
            }
            return true;
        }

        function refresh(){
            for(var index = 0;index<repeater.count;index++){
                if(root.blocks != null && root.blocks[Math.floor(index/10)] != null && root.blocks[Math.floor(index/10)][index%10] != null && root.blocks[Math.floor(index/10)][index%10] === 1){
                    repeater.itemAt(index).color = "lightgray";
                }
                else if(root.currentBlocks != null && index%10-root.xOffset-3 >= 0 && index%10-root.xOffset-3 < 4
                        && root.currentBlocks[(Math.floor(index/10)-root.yOffset+2)*4+index%10-root.xOffset-3] != null
                        && root.currentBlocks[(Math.floor(index/10)-root.yOffset+2)*4+index%10-root.xOffset-3] === 1){
                    repeater.itemAt(index).color = "green";
                }
                else {
                    repeater.itemAt(index).color = "white";
                }
            }
        }

    }
}
