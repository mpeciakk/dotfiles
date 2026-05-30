import QtQuick

// Square icon image with crisp source rendering. Set `size` and `source`.
Image {
    property int size: 16

    width: size
    height: size
    sourceSize.width: size
    sourceSize.height: size
    fillMode: Image.PreserveAspectFit
}
