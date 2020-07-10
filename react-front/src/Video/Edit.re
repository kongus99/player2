[@react.component]
let make = (~id: int, ~title: string, ~videoId: string) => {
  let (modalVisible, setModalVisible) = React.useState(() => false);

  Bootstrap.(
    <>
      <Button onClick={() => setModalVisible(_ => true)}>
        {React.string("Edit")}
      </Button>
      <Modal
        size="lg" show=modalVisible onHide={() => setModalVisible(_ => false)}>
        <Modal.Body>
          <Save initial={id: Some(id), title, videoId} />
        </Modal.Body>
      </Modal>
    </>
  );
};
