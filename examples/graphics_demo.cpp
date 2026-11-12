// graphics.h starter (Turbo C++ style). Windows + MinGW only:
//   ./run.sh -g -f examples/graphics_demo.cpp
//
// libbgi is old and draws into a Win32 window with its own event loop; this is
// why GRAPHICS=ON links the static lib and disables the console with
// -static-libgcc -static-libstdc++ (see CMakeLists.txt).
#include <graphics.h>

int main() {
    int gd = DETECT;
    int gm;

    initgraph(&gd, &gm, NULL);

    line(0, 0, getmaxx(), getmaxy());
    outtextxy(10, 10, (char*)"Press any key to exit");
    getch();

    closegraph();
    return 0;
}
