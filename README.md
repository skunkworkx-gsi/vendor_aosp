# inital install

mkdir android

git clone https://github.com/skunkworkx-gsi/vendor_aosp.git -b q vendor/aosp

cd vendor/aosp/treble

bash first_install.sh 

# after inital install

cd ../../../

bash build_treble.sh
